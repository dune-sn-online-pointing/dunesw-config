import argparse

def parse_logfile(logfile, nevents=5, print_header=False, output="footprintSummary.txt"):
    """
    Parse the simulation log file to extract execution times and memory usage.
    Args:
        logfile (str): Path to the log file.
        nevents (int): Number of events to process.
        print_header (bool): Whether to print the header in the output file.
        output (str): Output file name.
    """
    
    # Check if the file exists
    with open(logfile, 'r') as f:
        lines = f.readlines()

    # Extract execution times
    avg_times =     [float(line.split()[3]) for line in lines if "Full event" in line]
    vmpeak_vals =   [float(line.split()[-2]) for line in lines if "(VmPeak)" in line]
    vmhwm_vals =    [float(line.split()[-2]) for line in lines if "(VmHWM)" in line]

    # Extract total times for each stage
    gen_total =     [float(line.split()[2]) for line in lines if "Generation took" in line]
    g4_total =      [float(line.split()[3]) for line in lines if "G4 simulation took" in line]
    detsim_total =  [float(line.split()[2]) for line in lines if "Detsim took" in line]
    reco_total =    [float(line.split()[2]) for line in lines if "Reconstruction took" in line]

    # NOTE some custom fcl dont print memory summary, maybe add  
    if len(avg_times) != 4: #or len(vmpeak_vals) != 4 or len(vmhwm_vals) != 4:
        raise ValueError(f"Expected 4 values for each metric, got: "
                         f"{len(avg_times)} avg_times, {len(vmpeak_vals)} VmPeak, {len(vmhwm_vals)} VmHWM")

    # Compute init times
    init_gen = gen_total[0] - (avg_times[0] * nevents)
    init_g4 = g4_total[0] - (avg_times[1] * nevents)
    init_detsim = detsim_total[0] - (avg_times[2] * nevents)
    init_reco = reco_total[0] - (avg_times[3] * nevents)

    # Memory usage
    memory_usage = max(vmhwm_vals)


    # Find the reco1.root file size, divide by nevents and convert to MB 
    # TODO not the best, new sims have a printout like "Size of the reco file is"
    reco1_file = [line for line in lines if "reco1.root" in line and "dune" in line and "rw" in line]
    reco1_size = 0
    for line in reco1_file:
        parts = line.split()
        if len(parts) >= 5:
            size_str = parts[4]
            size = int(size_str)
            reco1_size += size
            reco1_size_mb = reco1_size / (1024 * 1024) # MB
            reco1_size_mb /= nevents
            break    

    # Print and save summary table
    header = f"Gen init\tExec time Gen (s/evt)\tInit G4\tExec time G4 (s/evt)\t" \
             f"Init detsim\tExec time Detsim (s/evt)\tInit reco1\tExec time reco1 (s/evt)\tMax Memory (MB)\tMemory/evt (MB)" 
    
    row = f"{init_gen:.3f}\t{avg_times[0]:.3f}\t{init_g4:.3f}\t{avg_times[1]:.3f}\t" \
          f"{init_detsim:.3f}\t{avg_times[2]:.3f}\t{init_reco:.3f}\t{avg_times[3]:.3f}\t" \
            f"{memory_usage:.3f}\t{reco1_size_mb:.3f}"

    print(f"\nParsed file: {logfile}\n")
    if (print_header):
        print(header)
    print(row)

    with open(output, "a") as fout:
        if (print_header):
            fout.write(header + "\n")
        fout.write(row + "\n")

    print("\nSummary table has been written to " + output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse simulation log file.")
    parser.add_argument("-f", "--file",             required=True,              help="Path to simulation log file.")
    parser.add_argument("-p", "--print-header",     action="store_true", help="Print header in the output file.")
    parser.add_argument("-n", "--nevents",          type=int, default=10,       help="Number of events to process (default: 10)")
    parser.add_argument("-o", "--output",           type=str, default="footprintSummary.txt",  help="Output file name (default: footprintSummary.txt)")
    args = parser.parse_args()
    
    # print summary table
    print ("selected options:")
    print (f"  logfile: {args.file}")
    print (f"  nevents: {args.nevents}")
    print (f"  print header: {args.print_header}")
    print (f"  output file: {args.output}")

    parse_logfile(args.file, nevents=args.nevents, print_header=args.print_header, output=args.output)
    
