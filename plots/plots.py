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

def get_time(module, rows):
    if "time" in rows[0][module]:
        return [row[module]["time"] for row in rows]
    else:
        return []

def plot_times(module, operations, times):
    if times == []:
        return None
    else:
        plt.plot(operations, times, label=module)


def main():
    file  = get_args()
    with open(file, 'r') as f:
        data = json.loads(f.read())
        results = data["results"]
        operations = [x["operations"] for x in results]

        stdlib_times = get_time("stdlib", results)
        vial_times = get_time("vial", results)
        phoenix_times = get_time("phoenix", results)

        plot_times('Existing CRDT', operations, phoenix_times)
        plot_times('Specialised CRDT', operations, vial_times)
        plot_times('Standard Library', operations, stdlib_times)

        plt.xlabel('Operations')
        plt.ylabel('Time (microseconds)')
        plt.legend()
        plt.show()

if __name__ == "__main__":
    main()
