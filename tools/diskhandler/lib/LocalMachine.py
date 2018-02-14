import subprocess
import time

def run_command(cmd, wait_for_done=True):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if wait_for_done:
        stdout, stderr = p.communicate()
        stdout = stdout.rstrip()
        stderr = stderr.rstrip()
        exit_code = p.returncode
    return exit_code, stdout, stderr

def text_to_matrix_converter(stdin):
    text_matrix = []
    lines = stdin.split("\n")
    for line in lines:
        line = line.rstrip()
        words_in_line = line.split(" ")
        words_buffer = []
        for word in words_in_line:
            if word != "":
                words_buffer.append(word)
        text_matrix.append(words_buffer)
    return text_matrix

def print_text_matrix(textmatrix):
    print(textmatrix)
    for lines in textmatrix:
        word_string = ""
        for word in lines:
            word_string += word + " "
        print(word_string + "\n")

if __name__ == "__main__":
    exitcode, stdout, stderr = run_command("ls -lh /")
    print("exitcode: {}\nstdout: {}\nstderr:{}".format(exitcode, stdout, stderr))

    textmatrix = text_to_matrix_converter(stdout)
    print_text_matrix(textmatrix)
