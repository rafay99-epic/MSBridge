# #!/usr/bin/env python3
# """
# Flutter Test Runner with Clean Output
# Runs flutter tests and presents results in a readable format
# """

# import subprocess
# import re
# import sys
# from datetime import datetime
# from typing import List, Dict, Tuple
# import json

# class Colors:
#     """ANSI color codes for terminal output"""
#     RED = '\033[91m'
#     GREEN = '\033[92m'
#     YELLOW = '\033[93m'
#     BLUE = '\033[94m'
#     MAGENTA = '\033[95m'
#     CYAN = '\033[96m'
#     WHITE = '\033[97m'
#     BOLD = '\033[1m'
#     UNDERLINE = '\033[4m'
#     END = '\033[0m'

# class TestResult:
#     def __init__(self):
#         self.passed = 0
#         self.failed = 0
#         self.skipped = 0
#         self.total_time = ""
#         self.failed_tests = []
#         self.passed_tests = []
#         self.errors = []

# class FlutterTestRunner:
#     def __init__(self):
#         self.result = TestResult()
    
#     def run_tests(self, additional_args: List[str] = None) -> bool:
#         """Run flutter test command and capture output"""
#         cmd = ["flutter", "test"]
#         if additional_args:
#             cmd.extend(additional_args)
        
#         print(f"{Colors.BLUE}🚀 Running Flutter Tests...{Colors.END}")
#         print(f"{Colors.CYAN}Command: {' '.join(cmd)}{Colors.END}\n")
        
#         try:
#             process = subprocess.run(
#                 cmd,
#                 capture_output=True,
#                 text=True,
#                 timeout=300  # 5 minutes timeout
#             )
            
#             self.parse_output(process.stdout, process.stderr)
#             return process.returncode == 0
            
#         except subprocess.TimeoutExpired:
#             print(f"{Colors.RED}❌ Test execution timed out!{Colors.END}")
#             return False
#         except FileNotFoundError:
#             print(f"{Colors.RED}❌ Flutter command not found! Make sure Flutter is installed.{Colors.END}")
#             return False
#         except Exception as e:
#             print(f"{Colors.RED}❌ Error running tests: {e}{Colors.END}")
#             return False
    
#     def parse_output(self, stdout: str, stderr: str):
#         """Parse flutter test output and extract meaningful information"""
#         lines = stdout.split('\n') + stderr.split('\n')
        
#         current_test = None
#         in_exception = False
#         exception_lines = []
        
#         for line in lines:
#             line = line.strip()
#             if not line:
#                 continue
            
#             # Extract test results (e.g., "00:04 +173 -30:")
#             result_match = re.match(r'(\d{2}:\d{2})\s+\+(\d+)\s+-(\d+):', line)
#             if result_match:
#                 self.result.total_time = result_match.group(1)
#                 self.result.passed = int(result_match.group(2))
#                 self.result.failed = int(result_match.group(3))
            
#             # Extract individual test results
#             if ': ' in line and ('PASS' in line or 'FAIL' in line or '[E]' in line):
#                 test_info = self.extract_test_info(line)
#                 if test_info:
#                     current_test = test_info
#                     if '[E]' in line or 'FAIL' in line:
#                         self.result.failed_tests.append(test_info)
#                     else:
#                         self.result.passed_tests.append(test_info)
            
#             # Extract exceptions
#             if '═══════════════════════════════════════════════' in line:
#                 if in_exception:
#                     # End of exception, process it
#                     self.process_exception(exception_lines, current_test)
#                     exception_lines = []
#                 in_exception = not in_exception
#             elif in_exception:
#                 exception_lines.append(line)
            
#             # Extract "To run this test again" commands
#             if line.startswith('To run this test again:'):
#                 if current_test:
#                     current_test['rerun_command'] = line.replace('To run this test again: ', '')
    
#     def extract_test_info(self, line: str) -> Dict:
#         """Extract test information from a result line"""
#         # Pattern for test results like: "00:04 +173 -30: /path/to/test.dart: Test Name [E]"
#         pattern = r'(\d{2}:\d{2})\s+[+\-\d\s:]+([^:]+\.dart):\s*(.+?)(?:\s+\[E\])?$'
#         match = re.match(pattern, line)
        
#         if match:
#             return {
#                 'time': match.group(1),
#                 'file': match.group(2).strip(),
#                 'name': match.group(3).strip(),
#                 'status': 'FAILED' if '[E]' in line else 'PASSED',
#                 'rerun_command': None
#             }
#         return None
    
#     def process_exception(self, exception_lines: List[str], current_test: Dict):
#         """Process and clean up exception information"""
#         if not exception_lines:
#             return
        
#         error_info = {
#             'test': current_test['name'] if current_test else 'Unknown Test',
#             'file': current_test['file'] if current_test else 'Unknown File',
#             'type': 'Unknown Error',
#             'message': '',
#             'widget': '',
#             'line_number': None
#         }
        
#         # Extract error type and message
#         for line in exception_lines[:10]:  # Check first 10 lines for key info
#             if 'EXCEPTION CAUGHT BY' in line:
#                 error_info['type'] = line.replace('EXCEPTION CAUGHT BY', '').replace('╞', '').strip()
#             elif line.startswith('The following'):
#                 error_info['message'] = line
#             elif 'error-causing widget was:' in line:
#                 widget_match = re.search(r'widget was:\s*(.+)', line)
#                 if widget_match:
#                     error_info['widget'] = widget_match.group(1).strip()
        
#         # Extract line number from stack trace
#         for line in exception_lines:
#             if 'ui_rendering_test.dart:' in line:
#                 line_match = re.search(r'ui_rendering_test\.dart:(\d+)', line)
#                 if line_match:
#                     error_info['line_number'] = line_match.group(1)
#                     break
        
#         self.result.errors.append(error_info)
    
#     def display_results(self):
#         """Display test results in a clean, readable format"""
#         print("\n" + "="*80)
#         print(f"{Colors.BOLD}{Colors.CYAN}📊 FLUTTER TEST RESULTS{Colors.END}")
#         print("="*80)
        
#         # Summary
#         total_tests = self.result.passed + self.result.failed
#         success_rate = (self.result.passed / total_tests * 100) if total_tests > 0 else 0
        
#         print(f"\n{Colors.BOLD}📈 SUMMARY:{Colors.END}")
#         print(f"  ⏱️  Total Time: {Colors.CYAN}{self.result.total_time}{Colors.END}")
#         print(f"  📊 Total Tests: {Colors.BLUE}{total_tests}{Colors.END}")
#         print(f"  ✅ Passed: {Colors.GREEN}{self.result.passed}{Colors.END}")
#         print(f"  ❌ Failed: {Colors.RED}{self.result.failed}{Colors.END}")
#         print(f"  📊 Success Rate: {Colors.GREEN if success_rate >= 80 else Colors.YELLOW if success_rate >= 60 else Colors.RED}{success_rate:.1f}%{Colors.END}")
        
#         # Failed Tests
#         if self.result.failed_tests:
#             print(f"\n{Colors.BOLD}❌ FAILED TESTS ({len(self.result.failed_tests)}):{Colors.END}")
#             for i, test in enumerate(self.result.failed_tests, 1):
#                 print(f"\n  {Colors.RED}{i}.{Colors.END} {Colors.BOLD}{test['name']}{Colors.END}")
#                 print(f"     📁 File: {Colors.CYAN}{test['file']}{Colors.END}")
#                 if test.get('rerun_command'):
#                     print(f"     🔄 Rerun: {Colors.YELLOW}{test['rerun_command']}{Colors.END}")
        
#         # Error Details
#         if self.result.errors:
#             print(f"\n{Colors.BOLD}🐛 ERROR DETAILS:{Colors.END}")
#             for i, error in enumerate(self.result.errors, 1):
#                 print(f"\n  {Colors.RED}Error {i}:{Colors.END} {Colors.BOLD}{error['test']}{Colors.END}")
#                 print(f"     📄 File: {Colors.CYAN}{error['file']}{Colors.END}")
#                 print(f"     🏷️  Type: {Colors.MAGENTA}{error['type']}{Colors.END}")
#                 if error['line_number']:
#                     print(f"     📍 Line: {Colors.YELLOW}{error['line_number']}{Colors.END}")
#                 if error['widget']:
#                     print(f"     🎨 Widget: {Colors.BLUE}{error['widget']}{Colors.END}")
#                 if error['message']:
#                     print(f"     💬 Message: {Colors.WHITE}{error['message'][:100]}...{Colors.END}")
        
#         # Recent Passed Tests (show last 5)
#         if self.result.passed_tests:
#             recent_passed = self.result.passed_tests[-5:] if len(self.result.passed_tests) > 5 else self.result.passed_tests
#             print(f"\n{Colors.BOLD}✅ RECENT PASSED TESTS ({len(recent_passed)} of {len(self.result.passed_tests)}):{Colors.END}")
#             for test in recent_passed:
#                 print(f"  ✅ {Colors.GREEN}{test['name']}{Colors.END}")
        
#         print("\n" + "="*80)
        
#         # Final status
#         if self.result.failed > 0:
#             print(f"{Colors.RED}{Colors.BOLD}💥 TESTS FAILED - {self.result.failed} test(s) need attention{Colors.END}")
#         else:
#             print(f"{Colors.GREEN}{Colors.BOLD}🎉 ALL TESTS PASSED!{Colors.END}")
        
#         print("="*80 + "\n")

# def main():
#     """Main function to run the Flutter test runner"""
#     print(f"{Colors.BOLD}{Colors.CYAN}Flutter Test Runner v1.0{Colors.END}")
#     print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
#     runner = FlutterTestRunner()
    
#     # Get additional arguments from command line
#     additional_args = sys.argv[1:] if len(sys.argv) > 1 else None
    
#     success = runner.run_tests(additional_args)
#     runner.display_results()
    
#     # Exit with appropriate code
#     sys.exit(0 if success else 1)

# if __name__ == "__main__":
#     main()

#!/usr/bin/env python3
"""
Flutter Test Runner with Clean Output
Runs flutter tests and presents results in a readable format
"""

import subprocess
import re
import sys
from datetime import datetime
from typing import List, Dict, Tuple
import json

class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

class TestResult:
    def __init__(self):
        self.passed = 0
        self.failed = 0
        self.skipped = 0
        self.total_time = ""
        self.failed_tests = []
        self.passed_tests = []
        self.errors = []

class FlutterTestRunner:
    def __init__(self):
        self.result = TestResult()
    
    def run_tests(self, additional_args: List[str] = None) -> bool:
        """Run flutter test command and capture output"""
        cmd = ["flutter", "test"]
        if additional_args:
            cmd.extend(additional_args)
        
        print(f"{Colors.BLUE}🚀 Running Flutter Tests...{Colors.END}")
        print(f"{Colors.CYAN}Command: {' '.join(cmd)}{Colors.END}\n")
        
        try:
            process = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300  # 5 minutes timeout
            )
            
            self.parse_output(process.stdout, process.stderr)
            return process.returncode == 0
            
        except subprocess.TimeoutExpired:
            print(f"{Colors.RED}❌ Test execution timed out!{Colors.END}")
            return False
        except FileNotFoundError:
            print(f"{Colors.RED}❌ Flutter command not found! Make sure Flutter is installed.{Colors.END}")
            return False
        except Exception as e:
            print(f"{Colors.RED}❌ Error running tests: {e}{Colors.END}")
            return False
    
    def parse_output(self, stdout: str, stderr: str):
        """Parse flutter test output and extract meaningful information"""
        lines = stdout.split('\n') + stderr.split('\n')
        
        current_test = None
        in_exception = False
        exception_lines = []
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Extract test results (e.g., "00:04 +173 -30:")
            result_match = re.match(r'(\d{2}:\d{2})\s+\+(\d+)\s+-(\d+):', line)
            if result_match:
                self.result.total_time = result_match.group(1)
                self.result.passed = int(result_match.group(2))
                self.result.failed = int(result_match.group(3))
            
            # Extract individual test results
            if ': ' in line and ('PASS' in line or 'FAIL' in line or '[E]' in line):
                test_info = self.extract_test_info(line)
                if test_info:
                    current_test = test_info
                    if '[E]' in line or 'FAIL' in line:
                        self.result.failed_tests.append(test_info)
                    else:
                        self.result.passed_tests.append(test_info)
            
            # Extract exceptions
            if '═══════════════════════════════════════════════' in line:
                if in_exception:
                    # End of exception, process it
                    self.process_exception(exception_lines, current_test)
                    exception_lines = []
                in_exception = not in_exception
            elif in_exception:
                exception_lines.append(line)
            
            # Extract "To run this test again" commands
            if line.startswith('To run this test again:'):
                if current_test:
                    current_test['rerun_command'] = line.replace('To run this test again: ', '')
    
    def extract_test_info(self, line: str) -> Dict:
        """Extract test information from a result line"""
        # Pattern for test results like: "00:04 +173 -30: /path/to/test.dart: Test Name [E]"
        pattern = r'(\d{2}:\d{2})\s+[+\-\d\s:]+([^:]+\.dart):\s*(.+?)(?:\s+\[E\])?$'
        match = re.match(pattern, line)
        
        if match:
            return {
                'time': match.group(1),
                'file': match.group(2).strip(),
                'name': match.group(3).strip(),
                'status': 'FAILED' if '[E]' in line else 'PASSED',
                'rerun_command': None
            }
        return None
    
    def process_exception(self, exception_lines: List[str], current_test: Dict):
        """Process and clean up exception information"""
        if not exception_lines:
            return
        
        error_info = {
            'test': current_test['name'] if current_test else 'Unknown Test',
            'file': current_test['file'] if current_test else 'Unknown File',
            'type': 'Unknown Error',
            'message': '',
            'full_message': '',
            'widget': '',
            'line_number': None,
            'stack_trace': [],
            'relevant_error_widget': '',
            'overflow_info': '',
            'exception_type': '',
            'full_stack': '\n'.join(exception_lines)
        }
        
        # Extract error type and detailed information
        in_stack_trace = False
        
        for i, line in enumerate(exception_lines):
            # Extract exception header
            if 'EXCEPTION CAUGHT BY' in line:
                error_info['type'] = line.replace('EXCEPTION CAUGHT BY', '').replace('╞', '').strip()
            
            # Extract main error message
            elif line.startswith('The following'):
                error_info['message'] = line
                # Get next few lines for full message
                full_msg_lines = [line]
                for j in range(i+1, min(i+5, len(exception_lines))):
                    if exception_lines[j] and not exception_lines[j].startswith('The relevant'):
                        full_msg_lines.append(exception_lines[j])
                    else:
                        break
                error_info['full_message'] = '\n'.join(full_msg_lines)
            
            # Extract widget causing error
            elif 'error-causing widget was:' in line:
                widget_match = re.search(r'widget was:\s*(.+)', line)
                if widget_match:
                    error_info['widget'] = widget_match.group(1).strip()
            
            # Extract relevant error-causing widget
            elif 'The relevant error-causing widget was:' in line:
                if i+1 < len(exception_lines):
                    error_info['relevant_error_widget'] = exception_lines[i+1].strip()
            
            # Extract overflow information
            elif 'overflowed by' in line:
                error_info['overflow_info'] = line.strip()
            
            # Extract exception type (like Exception, AssertionError, etc.)
            elif line.startswith('Exception:') or line.startswith('AssertionError:') or line.startswith('RenderFlex'):
                error_info['exception_type'] = line.strip()
            
            # Extract stack trace
            elif line.startswith('#') and ('(' in line and ')' in line):
                in_stack_trace = True
                error_info['stack_trace'].append(line.strip())
            elif in_stack_trace and line.strip():
                if not line.startswith('#') and not line.startswith('...'):
                    in_stack_trace = False
                else:
                    error_info['stack_trace'].append(line.strip())
        
        # Extract line number from stack trace or file paths
        for line in exception_lines:
            if '.dart:' in line:
                line_match = re.search(r'\.dart:(\d+)', line)
                if line_match:
                    error_info['line_number'] = line_match.group(1)
                    break
        
        self.result.errors.append(error_info)
    
    def display_results(self):
        """Display test results in a clean, readable format"""
        print("\n" + "="*80)
        print(f"{Colors.BOLD}{Colors.CYAN}📊 FLUTTER TEST RESULTS{Colors.END}")
        print("="*80)
        
        # Summary
        total_tests = self.result.passed + self.result.failed
        success_rate = (self.result.passed / total_tests * 100) if total_tests > 0 else 0
        
        print(f"\n{Colors.BOLD}📈 SUMMARY:{Colors.END}")
        print(f"  ⏱️  Total Time: {Colors.CYAN}{self.result.total_time}{Colors.END}")
        print(f"  📊 Total Tests: {Colors.BLUE}{total_tests}{Colors.END}")
        print(f"  ✅ Passed: {Colors.GREEN}{self.result.passed}{Colors.END}")
        print(f"  ❌ Failed: {Colors.RED}{self.result.failed}{Colors.END}")
        print(f"  📊 Success Rate: {Colors.GREEN if success_rate >= 80 else Colors.YELLOW if success_rate >= 60 else Colors.RED}{success_rate:.1f}%{Colors.END}")
        
        # Failed Tests
        if self.result.failed_tests:
            print(f"\n{Colors.BOLD}❌ FAILED TESTS ({len(self.result.failed_tests)}):{Colors.END}")
            for i, test in enumerate(self.result.failed_tests, 1):
                print(f"\n  {Colors.RED}{i}.{Colors.END} {Colors.BOLD}{test['name']}{Colors.END}")
                print(f"     📁 File: {Colors.CYAN}{test['file']}{Colors.END}")
                if test.get('rerun_command'):
                    print(f"     🔄 Rerun: {Colors.YELLOW}{test['rerun_command']}{Colors.END}")
        
        # Quick Error Summary
        if self.result.errors:
            print(f"\n{Colors.BOLD}🐛 ERROR SUMMARY ({len(self.result.errors)}):{Colors.END}")
            for i, error in enumerate(self.result.errors, 1):
                print(f"\n  {Colors.RED}Error {i}:{Colors.END} {Colors.BOLD}{error['test']}{Colors.END}")
                print(f"     📄 File: {Colors.CYAN}{error['file']}{Colors.END}")
                print(f"     🏷️  Type: {Colors.MAGENTA}{error['type']}{Colors.END}")
                if error['line_number']:
                    print(f"     📍 Line: {Colors.YELLOW}{error['line_number']}{Colors.END}")
                if error['widget']:
                    print(f"     🎨 Widget: {Colors.BLUE}{error['widget']}{Colors.END}")
                if error['message']:
                    print(f"     💬 Message: {Colors.WHITE}{error['message'][:100]}...{Colors.END}")
        
        # DETAILED ERROR ANALYSIS
        if self.result.errors:
            print(f"\n{Colors.BOLD}🔍 DETAILED ERROR ANALYSIS:{Colors.END}")
            print("="*80)
            
            for i, error in enumerate(self.result.errors, 1):
                print(f"\n{Colors.RED}{Colors.BOLD}═══ ERROR {i} ═══{Colors.END}")
                print(f"{Colors.BOLD}Test:{Colors.END} {error['test']}")
                print(f"{Colors.BOLD}File:{Colors.END} {Colors.CYAN}{error['file']}{Colors.END}")
                print(f"{Colors.BOLD}Type:{Colors.END} {Colors.MAGENTA}{error['type']}{Colors.END}")
                
                if error['line_number']:
                    print(f"{Colors.BOLD}Line:{Colors.END} {Colors.YELLOW}{error['line_number']}{Colors.END}")
                
                if error['exception_type']:
                    print(f"{Colors.BOLD}Exception:{Colors.END} {Colors.RED}{error['exception_type']}{Colors.END}")
                
                if error['overflow_info']:
                    print(f"{Colors.BOLD}Overflow:{Colors.END} {Colors.YELLOW}{error['overflow_info']}{Colors.END}")
                
                print(f"\n{Colors.BOLD}📄 FULL ERROR MESSAGE:{Colors.END}")
                print(f"{Colors.WHITE}{error['full_message'] if error['full_message'] else error['message']}{Colors.END}")
                
                if error['relevant_error_widget']:
                    print(f"\n{Colors.BOLD}🎨 ERROR-CAUSING WIDGET:{Colors.END}")
                    print(f"{Colors.BLUE}{error['relevant_error_widget']}{Colors.END}")
                
                if error['widget'] and error['widget'] != error['relevant_error_widget']:
                    print(f"\n{Colors.BOLD}🎨 RELATED WIDGET:{Colors.END}")
                    print(f"{Colors.BLUE}{error['widget']}{Colors.END}")
                
                if error['stack_trace']:
                    print(f"\n{Colors.BOLD}📚 KEY STACK TRACE (First 10 frames):{Colors.END}")
                    for j, frame in enumerate(error['stack_trace'][:10]):
                        # Highlight frames containing test files
                        if '.dart:' in frame and ('test' in frame or error['file'].split('/')[-1] in frame):
                            print(f"{Colors.YELLOW}  {frame}{Colors.END}")
                        else:
                            print(f"{Colors.WHITE}  {frame}{Colors.END}")
                    
                    if len(error['stack_trace']) > 10:
                        print(f"{Colors.CYAN}  ... and {len(error['stack_trace']) - 10} more frames{Colors.END}")
                
                # Provide debugging suggestions
                print(f"\n{Colors.BOLD}💡 DEBUGGING SUGGESTIONS:{Colors.END}")
                suggestions = self.get_debugging_suggestions(error)
                for suggestion in suggestions:
                    print(f"  • {Colors.GREEN}{suggestion}{Colors.END}")
                
                if i < len(self.result.errors):
                    print(f"\n{Colors.CYAN}{'─' * 80}{Colors.END}")
        
        # Recent Passed Tests (show last 5)
        if self.result.passed_tests:
            recent_passed = self.result.passed_tests[-5:] if len(self.result.passed_tests) > 5 else self.result.passed_tests
            print(f"\n{Colors.BOLD}✅ RECENT PASSED TESTS ({len(recent_passed)} of {len(self.result.passed_tests)}):{Colors.END}")
            for test in recent_passed:
                print(f"  ✅ {Colors.GREEN}{test['name']}{Colors.END}")
        
        print("\n" + "="*80)
        
        # Final status
        if self.result.failed > 0:
            print(f"{Colors.RED}{Colors.BOLD}💥 TESTS FAILED - {self.result.failed} test(s) need attention{Colors.END}")
        else:
            print(f"{Colors.GREEN}{Colors.BOLD}🎉 ALL TESTS PASSED!{Colors.END}")
        
        print("="*80 + "\n")
    
    def get_debugging_suggestions(self, error: Dict) -> List[str]:
        """Generate debugging suggestions based on error type and content"""
        suggestions = []
        
        error_text = (error.get('full_message', '') + ' ' + 
                     error.get('message', '') + ' ' + 
                     error.get('exception_type', '') + ' ' + 
                     error.get('type', '')).lower()
        
        # Widget-specific suggestions
        if 'renderflex overflowed' in error_text or 'overflow' in error_text:
            suggestions.extend([
                "Use Expanded or Flexible widgets to control flex children",
                "Consider using SingleChildScrollView for scrollable content",
                "Check if container sizes are too large for available space",
                "Add constraints to limit widget dimensions"
            ])
        
        if 'builder' in error.get('widget', '').lower():
            suggestions.extend([
                "Check if the Builder's build function handles null cases",
                "Verify all required data is available when Builder executes",
                "Consider using FutureBuilder or StreamBuilder for async data"
            ])
        
        if 'exception' in error_text and 'test error' in error_text:
            suggestions.extend([
                "This appears to be an intentional test exception",
                "Verify that error handling widgets are properly implemented",
                "Check if the test is expecting this exception to be caught"
            ])
        
        # File/Line specific suggestions
        if error.get('line_number'):
            suggestions.append(f"Check line {error['line_number']} in {error.get('file', 'the test file')}")
        
        # Widget library errors
        if 'widgets library' in error.get('type', '').lower():
            suggestions.extend([
                "This is a widget construction error - check widget parameters",
                "Verify all required parameters are provided to widgets",
                "Check for null values being passed to widgets"
            ])
        
        # Rendering errors
        if 'rendering library' in error.get('type', '').lower():
            suggestions.extend([
                "This is a layout/rendering error",
                "Check widget sizing and constraints",
                "Verify parent-child widget relationships"
            ])
        
        # Test framework errors
        if 'flutter test framework' in error.get('type', '').lower():
            suggestions.extend([
                "Multiple exceptions occurred during test execution",
                "Check test setup and teardown procedures",
                "Verify test environment is properly initialized"
            ])
        
        # Generic suggestions if no specific ones found
        if not suggestions:
            suggestions.extend([
                "Review the full error message and stack trace above",
                "Check the widget tree structure around the error location",
                "Verify test data and mocks are properly set up",
                "Consider adding debug prints to trace execution flow"
            ])
        
        return suggestions

def main():
    """Main function to run the Flutter test runner"""
    print(f"{Colors.BOLD}{Colors.CYAN}Flutter Test Runner v1.1{Colors.END}")
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    runner = FlutterTestRunner()
    
    # Get additional arguments from command line
    additional_args = sys.argv[1:] if len(sys.argv) > 1 else None
    
    success = runner.run_tests(additional_args)
    runner.display_results()
    
    # Exit with appropriate code
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()