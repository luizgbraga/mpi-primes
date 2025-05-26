# Parallel Prime Number Counter

A comparative study of parallel algorithms for counting prime numbers using MPI.

## Overview

This project implements and compares three versions of a prime number counting algorithm:
- **Sequential version**: Baseline implementation
- **Parallel v1**: Jump-based distribution (static load balancing)
- **Parallel v2**: Bag-of-tasks pattern (dynamic load balancing)

## How to run
```bash
# Copy files to the cluster
scp *.c *.sh *.qsub <cluster-path>
chmod +x *.sh *.qsub

# Submit all tests
./submit_all_tests.sh

# Monitor
./check_jobs.sh

# Collect results when done
./collect_results.sh

# Download results
scp <cluster-path>/resultados/resultados_finais.txt .

# Generate speedup graphs
python generate_graphs.py
```
