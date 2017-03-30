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

        plt.plot(operations, phoenix_times, label='Existing CRDT')
        plt.plot(operations, vial_times, label='Specialised CRDT')
        plt.plot(operations, stdlib_times, label='Standard Library')
        plt.xlabel('Operations')
        plt.ylabel('Time (microseconds)')
        plt.legend()
        plt.show()

if __name__ == "__main__":
    main()
