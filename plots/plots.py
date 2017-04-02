import getopt
import glob
import json
import matplotlib.pyplot as plt
import numpy as np
import sys

def get_args():
    args, remaining = getopt.getopt(sys.argv[1:], 'd:')
    if len(args) == 0:
        print('This requires a directory')
        exit()
    return args[0][1]

def get_time(module, rows):
    if "time" in rows[0][module]:
        return [row[module]["time"] for row in rows]
    else:
        return []

def parse_results(file):
    with open(file, 'r') as f:
        data = json.loads(f.read())
        results = data["results"]
        operations = [x["operations"] for x in results]

        stdlib_times = get_time("stdlib", results)
        vial_times = get_time("vial", results)
        phoenix_times = get_time("phoenix", results)

        result = {
                'stdlib': stdlib_times,
                'vial': vial_times,
                'phoenix': phoenix_times,
                'operations': operations
        }
        return result

def normalise(results, module):
    data = [result[module] for result in results]
    return np.mean(np.array(data), axis=0)



def plot_times(module, operations, times):
    if times == []:
        return None
    else:
        plt.plot(operations, times, label=module)


def main():
    directory  = get_args()
    data_files = glob.glob(f"{directory}/*.json")
    results = [parse_results(file) for file in data_files]

    operations = normalise(results, 'operations')

    stdlib_times = normalise(results, 'stdlib')
    vial_times = normalise(results, 'vial')
    phoenix_times = normalise(results, 'phoenix')

    plot_times('Existing CRDT', operations, phoenix_times)
    plot_times('Specialised CRDT', operations, vial_times)
    plot_times('Standard Library', operations, stdlib_times)

    plt.xlabel('Operations')
    plt.ylabel('Time (microseconds)')
    plt.legend()
    plt.show()

if __name__ == "__main__":
    main()
