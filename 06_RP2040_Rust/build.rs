use std::{env, fs, path::PathBuf};

fn main() {
    let manifest_dir = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());
    let out_dir = PathBuf::from(env::var_os("OUT_DIR").unwrap());

    let configured_path = env::var_os("FPGA_BITSTREAM").map(PathBuf::from);
    let bitstream = configured_path.unwrap_or_else(|| {
        manifest_dir.join("../FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin")
    });
    let bitstream = if bitstream.is_absolute() {
        bitstream
    } else {
        manifest_dir.join(bitstream)
    };

    println!("cargo:rerun-if-env-changed=FPGA_BITSTREAM");
    println!("cargo:rerun-if-changed={}", bitstream.display());
    println!("cargo:rerun-if-changed=memory.x");

    let bytes = fs::read(&bitstream).unwrap_or_else(|error| {
        panic!(
            "Cannot read FPGA MCU bitstream '{}': {error}. Generate FPGA_bitstream_MCU.bin in Renesas Go Configure first.",
            bitstream.display()
        )
    });
    if bytes.is_empty() {
        panic!("FPGA MCU bitstream is empty: {}", bitstream.display());
    }

    fs::write(out_dir.join("fpga_bitstream.bin"), bytes)
        .expect("copy FPGA bitstream into Cargo build directory");
    fs::copy(manifest_dir.join("memory.x"), out_dir.join("memory.x"))
        .expect("copy memory.x into Cargo build directory");
    println!("cargo:rustc-link-search={}", out_dir.display());
}