cfg_if! {
    if #[cfg(any(feature = "board-qemu", feature = "board-c910light"))] {
mod entry64;
pub use entry64::consts;
    } else {
mod boot_page_table;
pub mod consts;
mod entry;
    }}
