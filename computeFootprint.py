import argparse

def parse_logfile(logfile, nevents=5, print_header=False):
    with open(logfile, 'r') as f:
        lines = f.readlines()

    # Extract execution times
    avg_times = [float(line.split()[3]) for line in lines if "Full event" in line]
    vmpeak_vals = [float(line.split()[-2]) for line in lines if "(VmPeak)" in line]
    vmhwm_vals = [float(line.split()[-2]) for line in lines if "(VmHWM)" in line]

    # Extract total times for each stage
    gen_total = [float(line.split()[2]) for line in lines if "Generation took" in line]
    g4_total = [float(line.split()[3]) for line in lines if "G4 simulation took" in line]
    detsim_total = [float(line.split()[2]) for line in lines if "Detsim took" in line]
    reco_total = [float(line.split()[2]) for line in lines if "Reconstruction took" in line]

    # NOTE some custom fcl dont print memory summary, maybe add  
    if len(avg_times) != 4: #or len(vmpeak_vals) != 4 or len(vmhwm_vals) != 4:
        raise ValueError(f"Expected 4 values for each metric, got: "
                         f"{len(avg_times)} avg_times, {len(vmpeak_vals)} VmPeak, {len(vmhwm_vals)} VmHWM")

    # Compute per-event execution times
    

    # Compute init times
    init_gen = gen_total[0] - (avg_times[0] * nevents)
    init_g4 = g4_total[0] - (avg_times[1] * nevents)
    init_detsim = detsim_total[0] - (avg_times[2] * nevents)
    init_reco = reco_total[0] - (avg_times[3] * nevents)

    # Memory usage
    memory_usage = max(vmhwm_vals)

    # Print and save summary table
    header = f"Gen init\tExec time Gen (s/evt)\tInit G4\tExec time G4 (s/evt)\t" \
             f"Init detsim\tExec time Detsim (s/evt)\tInit reco1\tExec time reco1 (s/evt)\tMax Memory (MB)"
    
    row = f"{init_gen:.3f}\t{avg_times[0]:.3f}\t{init_g4:.3f}\t{avg_times[1]:.3f}\t" \
          f"{init_detsim:.3f}\t{avg_times[2]:.3f}\t{init_reco:.3f}\t{avg_times[3]:.3f}\t" \
            f"{memory_usage:.3f}"

    print(f"\nParsed file: {logfile}\n")
    if (print_header):
        print(header)
    print(row)

    with open("footprintSummary.txt", "a") as fout:
        if (print_header):
            fout.write(header + "\n")
        fout.write(row + "\n")

    print("\nSummary table has been written to footprintSummary.txt")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse simulation log file.")
    parser.add_argument("-f", "--file", required=True, help="Path to simulation log file.")
    parser.add_argument("-ph", "--print-header", type=bool, default=False, help="Print header in output file (default: False)")
    parser.add_argument("-n", "--nevents", type=int, default=5, help="Number of events to process (default: 5)")
    parser.add_argument("-o", "--output", default="footprintSummary.txt", help="Output file name (default: footprintSummary.txt)")
    args = parser.parse_args()
    
    # print summary table
    print ("selected options:")
    print (f"  logfile: {args.file}")
    print (f"  nevents: {args.nevents}")
    print (f"  print header: {args.print_header}")

    parse_logfile(args.file, nevents=5, print_header=args.print_header)
    
