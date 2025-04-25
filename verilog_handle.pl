#!/usr/bin/perl

use lib "../ch_verilog";
use Verilog_module;

my %v_argv_rule = (
    '-fl' => {'perl_type' => 'scalar'},
    '-f'  => {'perl_type' => 'array'},
    '-o'  => {'perl_type' => 'scalar'}
);

my @argv = @ARGV;   # 1 file_list_name
my %argv_hash;
my @file_list;
my %io_hash;
my @module_name_a;

my @top_input_a, @top_output_a, @top_inout_a;

# for $arg (@argv) {
#     print "$arg \n";
# }

$io_hash{'input'} = ();
$io_hash{'output'} = ();
$io_hash{'inout'} = ();

Verilog_module::argv_handle(\@argv, \%argv_hash);
for $k (keys %argv_hash) {
    if ($k eq '-f') {
        print "$k -> @{$argv_hash{$k}}\n";
    } else {
        print "$k -> $argv_hash{$k}\n";
    }
    
}
Verilog_module::read_argv(\$argv_hash{'-fl'}, \@file_list);
Verilog_module::read_sub_verilog(\@file_list, \%io_hash, \@module_name_a);
Verilog_module::split_generate_top_port(\%io_hash, \@top_input_a, \@top_output_a, \@top_inout_a);
Verilog_module::generate_top(\'top', \@top_input_a, \@top_output_a, \@top_inout_a, \%io_hash, \@module_name_a);

exit 0;
