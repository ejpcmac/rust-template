// Fragments to use in files.

export const MODULE_ATTRIBUTES = `
#![forbid(unsafe_code)]
#![deny(missing_docs)]
#![deny(unused_must_use)]
#![warn(rust_2018_idioms)]
#![warn(clippy::redundant_pub_crate)]
#![warn(clippy::unwrap_used)]
#![warn(clippy::use_self)]
`;

export const NOSTD_ATTRIBUTES = `
#![no_std]
#![no_main]
`;
