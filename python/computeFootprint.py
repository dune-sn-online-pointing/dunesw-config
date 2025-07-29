import argparse
import sys

def convert_size(str_):
    units = {"K": 1 / 1024, "M": 1, "G": 1024}
    if str_[-1] in units:
        return float(str_[:-1]) * units[str_[-1]]
    return float(str_)

def parse_logfile(logfile, nevents=10, print_header=False, output="footprintSummary.txt"):
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
    if len(vmhwm_vals) != 4: 
        raise ValueError(f"Expected 4 values for memory tracker, got: "
                         f"{len(vmhwm_vals)} VmHWM")

    # Compute init times
    init_gen = gen_total[0] - (avg_times[0] * nevents)
    init_g4 = g4_total[0] - (avg_times[1] * nevents)
    init_detsim = detsim_total[0] - (avg_times[2] * nevents)
    init_reco = reco_total[0] - (avg_times[3] * nevents)

    # Memory usage
    rss_memory = (vmhwm_vals) 
    print("RSS memory usage (VmHWM):")
    for i, mem in enumerate(rss_memory):
        print(f"  {i+1}: {mem:.3f} MB")
    
        
    # find string "Size of the gen file is" and get the size, it's the string right after
    gen_size_mb = next((line.split()[6] for line in lines if "Size of the gen file is" in line), "0")
    gen_size_mb = convert_size(gen_size_mb)/ nevents
    # find str "Size of the g4 file is" and get the size, it's the str right after
    g4_size_mb = next((line.split()[6]) for line in lines if "Size of the g4 file is" in line)
    g4_size_mb = convert_size(g4_size_mb) / nevents
    # find str "Size of the detsim file is" and get the size, it's the str right after
    detsim_size_mb = next((line.split()[6]) for line in lines if "Size of the detsim file is" in line)
    detsim_size_mb = convert_size(detsim_size_mb)/ nevents
    # find str "Size of the reco file is" and get the size, it's the str right after
    reco1_size_mb = next((line.split()[6]) for line in lines if "Size of the reco file is" in line)
    reco1_size_mb = convert_size(reco1_size_mb)/ nevents
  
    # Print and save summary table
    header = f"Gen init\tExec time Gen (s/evt)\tGen RSS (MB)\tGen Size (MB)\t" \
             f"Init G4\tExec time G4 (s/evt)\tG4 RSS (MB)\tG4 Size (MB)\t" \
             f"Init detsim\tExec time Detsim (s/evt)\tDetsim RSS (MB)\tDetsim Size (MB)\t" \
             f"Init reco1\tExec time reco1 (s/evt)\tReco1 RSS (MB)\tReco1 Size (MB)"
    
    row = f"{init_gen:.3f}\t{avg_times[0]:.3f}\t{rss_memory[0]:.3f}\t{gen_size_mb:.3f}\t" \
          f"{init_g4:.3f}\t{avg_times[1]:.3f}\t{rss_memory[1]:.3f}\t{g4_size_mb:.3f}\t" \
          f"{init_detsim:.3f}\t{avg_times[2]:.3f}\t{rss_memory[2]:.3f}\t{detsim_size_mb:.3f}\t" \
          f"{init_reco:.3f}\t{avg_times[3]:.3f}\t{rss_memory[3]:.3f}\t{reco1_size_mb:.3f}"
    
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
    
