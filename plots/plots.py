import getopt
import json
import matplotlib.pyplot as plt
import sys

def get_args():
    args, remaining = getopt.getopt(sys.argv[1:], 'i:')
    if len(args) == 0:
        print('This requires a file')
        exit()
    return args[0][1]


def main():
    file  = get_args()
    with open(file, 'r') as f:
        data = json.loads(f.read())
        results = data["results"]
        operations = [x["operations"] for x in results]
        stdlib_times = [x["stdlib"]["time"] for x in results]
        vial_times = [x["vial"]["time"] for x in results]
        phoenix_times = [x["phoenix"]["time"] for x in results]
        plt.plot(operations, stdlib_times, operations, vial_times, operations, phoenix_times)
        plt.show()

if __name__ == "__main__":
    main()
