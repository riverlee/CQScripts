Strand Bias Project
====================================

## Folder Structure

 * **align**
    * **bowtie** alignment by towtie (run_bowtie_pair.pl)
    * **firstalignment** alignment by bwa (run_bwa_pair.pl)
    * **realignment**  based on **firstalignment**, then realignment, recalibration and markdup.
      (run_gatk_realignment.pl, run_gatk_recalibration.pl, run_picard_markdup.pl)
    * **markdup** based on **firstalignment**, then markdup, recalibration and samtools BAQ 
      (run_picard_markdup.pl, run_gatk_recalibration.pl, run_samtools_BAQ.pl)
* **pileup**
    * **bowtie** alignment by towtie 
    * **firstalignment** alignment by bwa 
    * **realignment**  based on **firstalignment**, then realignment, recalibration and markdup.
    * **markdup** based on **firstalignment**, then markdup, recalibration and samtools BAQ 


