import unittest
import subprocess
import hashlib
import random
import string


class TestArgumentParsing(unittest.TestCase):
    def run_program(self, args):
        result = subprocess.run(['./kry'] + args, input="", text=True, capture_output=True)
        return result.stdout.strip(), result.returncode

    def test_no_args(self):
        output, returncode = self.run_program([])
        self.assertEqual(returncode, 1)
        self.assertIn("Usage:", output)

    def test_c_option(self):
        output, returncode = self.run_program(['-c'])
        self.assertEqual(returncode, 0)

    def test_s_option_without_k(self):
        output, returncode = self.run_program(['-s'])
        self.assertEqual(returncode, 3)

    def test_v_option_without_k_and_m(self):
        output, returncode = self.run_program(['-v'])
        self.assertEqual(returncode, 3)

    def test_v_option_without_k(self):
        output, returncode = self.run_program(['-m 12333', '-v'])
        self.assertEqual(returncode, 3)

    def test_v_option_without_m(self):
        output, returncode = self.run_program(["-k asdf", "-v"])
        self.assertEqual(returncode, 3)

    def test_v_option_with_short_m(self):
        output, returncode = self.run_program(["-k asdf", "-m 64symbolsareneeded", "-v"])
        self.assertEqual(returncode, 3)

    def test_e_option_without_m_n_and_a(self):
        output, returncode = self.run_program(['-e'])
        self.assertEqual(returncode, 3)


class TestSHA256(unittest.TestCase):
    def run_sha256(self, input_data):
        result = subprocess.run(['./kry', '-c'], input=input_data, text=True, capture_output=True)
        return result.stdout.strip()

    def test_empty_string(self):
        input_data = ""
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        # print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_simple_string(self):
        input_data = "heslo"
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        # print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_complex_string(self):
        input_data = "hello, world!"
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        # print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)
    
    def test_heslozprava(self):
        input_data = "heslozprave"
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        # print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_long_string(self):
        with open("sha256.cpp", "r") as file:
            input_data = file.read()
        expected_result = hashlib.sha256(input_data.encode()).hexdigest()
        actual_result = self.run_sha256(input_data)
        # print(actual_result + " =?= " + expected_result)
        
        self.assertEqual(actual_result, expected_result)

    def test_various_lengths(self):
        for i in range(257):
            input_data = "a" * i
            expected_result = hashlib.sha256(input_data.encode()).hexdigest()
            actual_result = self.run_sha256(input_data)
            
            self.assertEqual(actual_result, expected_result)


def generate_random_string(N):
    return ''.join(random.choice(string.ascii_letters + string.digits) for _ in range(N))


class TestVOption(unittest.TestCase):
    def run_program(self, args, _input=""):
        result = subprocess.run(['./kry'] + args, input=_input, text=True, capture_output=True)
        return result.stdout.strip(), result.returncode

    def test_v_option_without_args(self):
        output, returncode = self.run_program(['-v'])
        self.assertEqual(returncode, 3)

    def test_v_option_with_k_only(self):
        output, returncode = self.run_program(['-v', '-k', 'mykey'])
        self.assertEqual(returncode, 3)

    def test_v_option_with_m_only(self):
        output, returncode = self.run_program(['-v', '-m', 'mymac'])
        self.assertEqual(returncode, 3)

    def test_from_assignment(self):
        input_data = "zprava"
        key = "heslo"
        mac = "23158796a45a9392951d9a72dffd6a539b14a07832390b937b94a80ddb6dc18e"
        output, returncode = self.run_program(['-v', '-k', key, '-m', mac], _input=input_data)
        self.assertEqual(returncode, 0)

    def test_various(self):
        for i in range(33):
            for j in range(33):
                input_data = generate_random_string(i)
                key = generate_random_string(j)
                mac = hashlib.sha256((key + input_data).encode()).hexdigest()
                output, returncode = self.run_program(["-v", "-k", key, "-m", mac], _input=input_data)


if __name__ == '__main__':
    unittest.main()

