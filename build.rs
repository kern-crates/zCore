use std::io::Write;

fn main() {
    //println!("cargo:rerun-if-env-changed=PLATFORM");

    if std::env::var("TARGET").unwrap().contains("riscv64") {
        let kernel_base_addr: u64 = if std::env::var("PLATFORM").map_or(false, |p| p.contains("d1"))
        {
            0xffffffffc0100000
        } else {
            0xffffffff80200000
        };

        let mut fout = std::fs::File::create("src/platform/riscv/kernel-vars.ld").unwrap();
        writeln!(fout, "/* Generated by build.rs. DO NOT EDIT. */").unwrap();
        writeln!(
            fout,
            "PROVIDE_HIDDEN(BASE_ADDRESS = {:#x});",
            kernel_base_addr
        )
        .unwrap();
    } else if std::env::var("TARGET").unwrap().contains("aarch64") {
        println!("cargo:rustc-env=USER_IMG=prebuilt/linux/aarch64.img");
    }
}
