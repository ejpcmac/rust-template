// Rust and clippy lints.

export const LINTS = `
[workspace.lints.rust]
# Forbidden
unsafe_code = "forbid"
unsafe_op_in_unsafe_fn = "forbid"

# Denied
let_underscore = { level = "deny", priority = -1 }
missing_docs = "deny"
unused_must_use = "deny"

# Warnings
macro_use_extern_crate = "warn"
missing_abi = "warn"
missing_debug_implementations = "warn"
nonstandard_style = { level = "warn", priority = -1 }
rust_2018_idioms = { level = "warn", priority = -1 }
single_use_lifetimes = "warn"

[workspace.lints.clippy]
# Deny some lints from the restrictions set.
multiple_unsafe_ops_per_block = "deny"
undocumented_unsafe_blocks = "deny"

# Enable all pedantic warnings…
pedantic = { level = "warn", priority = -1 }
# …except a few.
case_sensitive_file_extension_comparisons = "allow"
inline_always = "allow"
linkedlist = "allow"
missing_errors_doc = "allow"
must_use_candidate = "allow"

# Enable many restrictions.
alloc_instead_of_core = "warn"
allow_attributes = "warn"
allow_attributes_without_reason = "warn"
as_conversions = "warn"
as_pointer_underscore = "warn"
as_underscore = "warn"
assertions_on_result_states = "warn"
cfg_not_test = "warn"
clone_on_ref_ptr = "warn"
dbg_macro = "warn"
default_numeric_fallback = "warn"
default_union_representation = "warn"
else_if_without_else = "warn"
empty_drop = "warn"
empty_enum_variants_with_brackets = "warn"
empty_structs_with_brackets = "warn"
error_impl_error = "warn"
exit = "warn"
expect_used = "warn"
field_scoped_visibility_modifiers = "warn"
filetype_is_file = "warn"
float_cmp_const = "warn"
format_push_string = "warn"
get_unwrap = "warn"
if_then_some_else_none = "warn"
indexing_slicing = "warn"
infinite_loop = "warn"
iter_over_hash_type = "warn"
let_underscore_must_use = "warn"
lossy_float_literal = "warn"
map_err_ignore = "warn"
mem_forget = "warn"
min_ident_chars = "warn"
missing_assert_message = "warn"
missing_docs_in_private_items = "warn"
mod_module_files = "warn"
multiple_inherent_impl = "warn"
mutex_atomic = "warn"
mutex_integer = "warn"
non_zero_suggestions = "warn"
panic = "warn"
panic_in_result_fn = "warn"
partial_pub_fields = "warn"
precedence_bits = "warn"
pub_without_shorthand = "warn"
rc_buffer = "warn"
rc_mutex = "warn"
redundant_test_prefix = "warn"
redundant_type_annotations = "warn"
renamed_function_params = "warn"
rest_pat_in_fully_bound_structs = "warn"
same_name_method = "warn"
semicolon_inside_block = "warn"
str_to_string = "warn"
string_lit_chars_any = "warn"
string_slice = "warn"
string_to_string = "warn"
tests_outside_test_module = "warn"
todo = "warn"
unnecessary_safety_comment = "warn"
unnecessary_safety_doc = "warn"
unneeded_field_pattern = "warn"
unseparated_literal_suffix = "warn"
unused_result_ok = "warn"
unused_trait_names = "warn"
unwrap_in_result = "warn"
unwrap_used = "warn"
verbose_file_reads = "warn"

# Other groups
# TODO: Enable this lint before publishing.
# cargo = { level = "warn", priority = -1 }
redundant_pub_crate = "warn"
use_self = "warn"
`;
