version 1.0


workflow bcftools_merge {
    input {
        Array[Array[File]] files_to_merge
        Array[String] output_prefixes
        Boolean missing_to_ref = false
        Int mem_gb = 16
    }

    scatter (pair in zip(files_to_merge, output_prefixes)) {
        call merge_vcfs {
            input: vcf_files = pair.left,
                out_prefix = pair.right,
                mem_gb = mem_gb,
                missing_to_ref = missing_to_ref
        }
    }

    output {
        Array[File] out_files = merge_vcfs.out_file
        Array[File] out_index_files = merge_vcfs.out_index_file
    }

    meta {
        author: "Adrienne Stilp"
        email: "amstilp@uw.edu"
    }
}

task merge_vcfs {
    input {
        Array[File] vcf_files
        String out_prefix
        Int mem_gb = 16
        Boolean missing_to_ref = false
    }

    Int disk_size = ceil(3*(size(vcf_files, "GB"))) + 10

    command <<<
        set -e -o pipefail

        echo "writing input file"
        cat ~{write_lines(vcf_files)} > files.txt
        cat files.txt


        echo "Merging files..."
        # Merge files.
        bcftools merge \
            --no-index \
            -l files.txt \
            ~{if missing_to_ref then "--missing-to-ref" else ""} \
            -o ~{out_prefix}.vcf.gz \
            --write-index
    >>>

    output {
        File out_file = "~{out_prefix}.vcf.gz"
        File out_index_file = "~{out_prefix}.vcf.gz.csi"
    }

    runtime {
        docker: "nanozoo/bcftools:1.19--1dccf69"
        disks: "local-disk " + disk_size + " SSD"
        memory: mem_gb + " GB"

    }
}
