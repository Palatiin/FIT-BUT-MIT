import unittest
import subprocess
import hashlib


class TestSHA256(unittest.TestCase):
    def run_sha256(self, input_data):
        result = subprocess.run(['./kry', '-c'], input=input_data, text=True, capture_output=True)
        return result.stdout.strip()

    def test_empty_string(self):
        input_data = ""
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_simple_string(self):
        input_data = "hello"
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_complex_string(self):
        input_data = "hello, world!"
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_long_string(self):
        with open("sha256.cpp", "r") as file:
            input_data = file.read()
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)


if __name__ == '__main__':
    unittest.main()

