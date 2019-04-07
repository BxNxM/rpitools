import os

def console_rows_columns():
    try:
        rows, columns = os.popen('stty size', 'r').read().split()
    except:
        rows, columns = 40, 150
    return int(rows)-1, int(columns)-2

if __name__ == "__main__":
    print(console_rows_columns())


