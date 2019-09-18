# Neon_pits

Repository (data and associated code) for:

Kaspari, Siler, Miller, Marshall and Weiser. Macroecological analysis of NEON pitfall traps.

### File 1: pipelineBr5.sh
A shell script to execute our bioinformatic pipeline for COI amplicons using the Br5 primer set.
This would need to be (lightly) modified for other primers

### File 2: non_overlapping.sh
A shell script to execute our bioinformatic pipeline for full length COI barcode amplicons.
Because reads (PE 250) do not overlap, R1 and R2 must be analyzed separately.
This file is optimized for the LepF1 and LepR1 primer sets
