#!/usr/bin/env python3
"""
Convert tccd ARM64 disassembly to C pseudo-code with hook points
"""

import re
import sys
from collections import defaultdict

def parse_disassembly(filepath):
    """Parse the disassembly file and extract functions with their instructions"""
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    functions = []
    current_function = None
    string_literals = {}
    
    for i, line in enumerate(lines):
        # Match instruction line with address
        addr_match = re.match(r'^([0-9a-f]{16})\s+(.+)', line)
        if not addr_match:
            continue
            
        addr = addr_match.group(1)
        instruction = addr_match.group(2).strip()
        
        # Extract string literals
        if 'literal pool for:' in line:
            literal_match = re.search(r'literal pool for: "([^"]+)"', line)
            if literal_match:
                string_literals[addr] = literal_match.group(1)
        
        # Detect function boundaries (pacibsp = function prologue on ARM64)
        if 'pacibsp' in instruction:
            if current_function:
                functions.append(current_function)
            current_function = {
                'start_addr': addr,
                'instructions': [],
                'strings': [],
                'calls': [],
                'name': None
            }
        
        if current_function:
            current_function['instructions'].append({
                'addr': addr,
                'instruction': instruction,
                'line': line.strip()
            })
    
    # Add last function
    if current_function:
        functions.append(current_function)
    
    # Second pass: identify function names from strings
    for func in functions:
        nearby_strings = []
        for inst in func['instructions'][:50]:  # Check first 50 instructions
            if inst['addr'] in string_literals:
                nearby_strings.append(string_literals[inst['addr']])
        
        # Try to name function based on strings
        func['strings'] = nearby_strings
        if nearby_strings:
            # Look for function-like names
            for s in nearby_strings:
                if 'TCC' in s and ('Access' in s or 'handle_' in s):
                    func['name'] = s
                    break
    
    return functions, string_literals

def identify_key_functions(functions):
    """Identify important TCC functions for hooking"""
    
    key_patterns = [
        'TCCAccessRequest',
        'TCCAccessSetInternal',
        'TCCAccessSetOverride',
        'TCCAccessGetOverride',
        'TCCAccessReset',
        'TCCAccessCopyInformation',
        'handle_TCC',
        'do_TCC',
        'check',
        'verify',
        'auth',
        'permission'
    ]
    
    important_funcs = []
    
    for func in functions:
        func_strings = ' '.join(func['strings'])
        if any(pattern.lower() in func_strings.lower() for pattern in key_patterns):
            important_funcs.append(func)
    
    return important_funcs

def generate_c_pseudocode(functions, string_literals, output_file):
    """Generate C pseudo-code with hook points"""
    
    with open(output_file, 'w') as f:
        f.write("""/*
 * tccd_decompiled.c
 * Auto-generated C pseudo-code from tccd binary disassembly
 * 
 * IMPORTANT: This file identifies hook points for TCC interception
 * Use these addresses with DYLD_INSERT_LIBRARIES or Frida
 */

#include <Foundation/Foundation.h>
#include <dispatch/dispatch.h>

// ============================================================================
// KEY HOOK POINTS FOR TCC INTERCEPTION
// ============================================================================

""")
        
        # Find and document key functions
        important_funcs = identify_key_functions(functions)
        
        f.write("/*\n * CRITICAL FUNCTIONS TO HOOK:\n *\n")
        for func in important_funcs[:20]:  # Top 20 important functions
            f.write(f" * Address: {func['start_addr']}\n")
            if func['name']:
                f.write(f" *   Name: {func['name']}\n")
            if func['strings']:
                f.write(f" *   Context: {func['strings'][0][:80]}\n")
            f.write(" *\n")
        f.write(" */\n\n")
        
        # Generate function stubs for key functions
        f.write("// ============================================================================\n")
        f.write("// FUNCTION PSEUDO-CODE\n")
        f.write("// ============================================================================\n\n")
        
        for idx, func in enumerate(important_funcs[:50]):  # Top 50 functions
            func_name = func['name'] if func['name'] else f"tccd_function_{func['start_addr']}"
            func_name = func_name.replace(' ', '_').replace(':', '_').replace('(', '').replace(')', '')
            func_name = re.sub(r'[^a-zA-Z0-9_]', '_', func_name)
            
            f.write(f"// Address: 0x{func['start_addr']}\n")
            f.write(f"void* {func_name}() {{\n")
            f.write(f"    // Start: 0x{func['start_addr']}\n")
            
            if func['strings']:
                f.write(f"    // Context strings:\n")
                for s in func['strings'][:5]:
                    f.write(f'    //   "{s}"\n')
            
            f.write(f"    // Instructions: {len(func['instructions'])}\n")
            
            # Show first few significant instructions
            f.write(f"    //\n")
            f.write(f"    // Key operations:\n")
            for inst in func['instructions'][:10]:
                if any(keyword in inst['instruction'].lower() for keyword in ['bl ', 'ret', 'cmp', 'cbz', 'tbnz']):
                    f.write(f"    //   {inst['addr']}: {inst['instruction'][:60]}\n")
            
            f.write(f"}}\n\n")
        
        # Add hook template
        f.write("""
// ============================================================================
// HOOK TEMPLATE (for use with DYLD_INSERT_LIBRARIES)
// ============================================================================

/*
 * Example hook using function interposition:
 *
 * #include <dlfcn.h>
 *
 * typedef void* (*original_func_t)(void*, void*, void*);
 *
 * void* hooked_TCCAccessRequest(void* arg1, void* arg2, void* arg3) {
 *     NSLog(@"[HOOK] TCCAccessRequest called!");
 *     
 *     // Call original
 *     original_func_t original = dlsym(RTLD_NEXT, "TCCAccessRequest");
 *     void* result = original(arg1, arg2, arg3);
 *     
 *     NSLog(@"[HOOK] Result: %@", result);
 *     return result;
 * }
 *
 * // Interpose
 * __attribute__((used)) static struct {
 *     const void* replacement;
 *     const void* replacee;
 * } TCCAccessRequest_interpose 
 *     __attribute__((section("__DATA,__interpose"))) = {
 *     (const void*)(unsigned long)&hooked_TCCAccessRequest,
 *     (const void*)(unsigned long)&TCCAccessRequest
 * };
 */

// ============================================================================
// IMPORTANT ADDRESSES FOR MANUAL HOOKING (Frida/LLDB)
// ============================================================================

/*
 * Use these addresses with Frida:
 *
 * Interceptor.attach(Module.findBaseAddress('tccd').add(0x<ADDRESS>), {
 *     onEnter: function(args) {
 *         console.log('[+] Function called');
 *     },
 *     onLeave: function(retval) {
 *         console.log('[+] Returned:', retval);
 *     }
 * });
 */

""")
        
        # List all functions with addresses
        f.write("/*\n * ALL FUNCTION ADDRESSES:\n")
        for func in functions[:100]:
            name = func['name'] if func['name'] else "unnamed"
            f.write(f" * 0x{func['start_addr']}: {name}\n")
        f.write(" */\n")

def main():
    input_file = '/Users/nathanvisser/Code/test/LibertyAccessControl/LibertyAccessControl/tccdToConvert'
    output_file = '/Users/nathanvisser/Code/test/LibertyAccessControl/LibertyAccessControl/tccdConverted_Full.c'
    
    print("[*] Parsing disassembly...")
    functions, string_literals = parse_disassembly(input_file)
    
    print(f"[+] Found {len(functions)} functions")
    print(f"[+] Found {len(string_literals)} string literals")
    
    print("[*] Generating C pseudo-code...")
    generate_c_pseudocode(functions, string_literals, output_file)
    
    print(f"[+] Output written to: {output_file}")
    print("\n[*] Key hook points identified:")
    
    important_funcs = identify_key_functions(functions)
    for func in important_funcs[:10]:
        print(f"    0x{func['start_addr']}: {func['name'] or 'unnamed'}")

if __name__ == '__main__':
    main()
