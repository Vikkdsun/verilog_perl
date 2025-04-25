package Verilog_module;

# my %v_argv_rule = (
#     '-fl' => {'perl_type' => 'scalar'},
#     '-f'  => {'perl_type' => 'array'},
#     '-o'  => {'perl_type' => 'scalar'}
# );

sub argv_handle {           # input argv, input hash of argv
    my ($argv_Ref, $argv_hash_Ref) = @_;
    my $temp_opt;

    for $ele (@$argv_Ref) {
        if ($ele =~ /^-/) {
            if (exists $argv_hash_Ref->{$ele}) {
                print "Error: only set option for one time!\n";
                exit 1;
            } else {
                $argv_hash_Ref->{$ele} = undef;
                $temp_opt = $ele;
            }
        } elsif (defined $temp_opt) {
            if ($temp_opt eq '-fl') {
                if (defined $argv_hash_Ref->{$temp_opt}) {
                    print "Error: the option of \"file list\" can be only set one parameter!\n";
                    exit 1;
                } else {
                    $argv_hash_Ref->{$temp_opt} = $ele;
                }
            } elsif ($temp_opt eq '-f') {
                push @{$argv_hash_Ref->{$temp_opt}}, $ele;
            } elsif ($temp_opt eq '-o') {
                if (defined $argv_hash_Ref->{$temp_opt}) {
                    print "Error: the option of \"output file\" can be only set one parameter!\n";
                    exit 1;
                } else {
                    $argv_hash_Ref->{$temp_opt} = $ele;
                }
            } else {
                print "Error: the option of \"$temp_opt\"is un-supported!\n";
                exit 1;
            }
        } else {
            print "Error: set option before set parameter! the \"$ele\" parameter has not been set its option!\n";
            exit 1;
        }
    }
}


sub read_argv {             # input file_list($), list_array
    my ($file_list_Ref, $file_list_aRef) = @_;
    my $count = 0;

    open my $file_list_f, "<", $$file_list_Ref or die "Error: No this file \"$$file_list_Ref\"!Read file list failed: $!"; # $! return line num
    while (my $line = <$file_list_f>) {
        chomp $line;
        next if ($line eq '');
        push @$file_list_aRef, $line;
    }
    print "All verilog files have been saved by list array:\n";
    for my $ele (@$file_list_aRef) {
        $count = $count + 1;
        print "$count : $ele\n";
    }
}

sub read_sub_verilog {  # input all module path array, hash of io port all, module_name_array
    my ($array_f, $hash_p, $module_name_aRef) = @_;
    my @line_array;
    my $flag_f;

    for $file_path (@$array_f) {
        open my $rf, "<", $file_path or die "Error: the sub file \"$file_path\" doesn't exists! $!";
        while (my $line = <$rf>) {
            chomp $line;
            next if ($line eq '');
            $line =~ s/\s+//g;
            # print $line, "\n";
            if ($line =~ /^module/) {
                my $line1 = $line;
                $line1 =~ s/^(module)?|\($//g;
                $flag_f = $line1;
                push @$module_name_aRef, $flag_f;
            }
            # print $flag_f;

            if ($line =~ /^input/) {
                # my %hash_abc;
                my $line2 = $line;
                $line2 =~ s/^(input){1,1}|,+$//g;
                # print $line2, "\n";
                # $hash_abc{$line2} = $flag_f;
                push @{$hash_p->{'input'}}, $line2.'-'.$flag_f;
            } elsif ($line =~ /^output/) {
                # my %hash_abc;
                my $line2 = $line;
                $line2 =~ s/^(output){1,1}|,+$//g;
                # $hash_abc{$line2} = $flag_f;
                push @{$hash_p->{'output'}}, $line2.'-'.$flag_f;
            } elsif ($line =~ /^inout/) {
                # my %hash_abc;
                my $line2 = $line;
                $line2 =~ s/^(inout){1,1}|,+$//g;
                # $hash_abc{$line2} = $flag_f;
                push @{$hash_p->{'inout'}}, $line2.'-'.$flag_f;
            }
        
        }
    }

}

sub split_generate_top_port {   # input hash of io port all, input list(only top), output list(only top), inout list(only top)
    my ($port_hash_ref, $input_list_ref, $output_list_ref, $inout_list_ref) = @_;

    for $key (keys %$port_hash_ref) {
        if ($key eq 'input') {
            my @array_p = @{$port_hash_ref->{$key}};
            my @array_psplit;

            for $ele (@array_p) {
                my @sp = split(/-/, $ele);
                if ($sp[0] =~ /^input_top/) {
                    push @$input_list_ref, $sp[0];
                }
            }
        } elsif ($key eq 'output') {
            my @array_p = @{$port_hash_ref->{$key}};
            my @array_psplit;

            for $ele (@array_p) {
                my @sp = split(/-/, $ele);
                if ($sp[0] =~ /^output_top/) {
                    push @$output_list_ref, $sp[0];
                }
            }
        } else {
            my @array_p = @{$port_hash_ref->{$key}};
            my @array_psplit;

            for $ele (@array_p) {
                my @sp = split(/-/, $ele);
                if ($sp[0] =~ /^inout_top/) {
                    push @$inout_list_ref, $sp[0];
                }
            }
        }
    }
}

sub generate_top {      # input module name, input list(only top), 
                        # output list(only top), inout list(only top), all ports hash, module name array
    my ($top_name_ref, $input_list_ref, $output_list_ref, $inout_list_ref, $phash, $mnarray) = @_;
    my $input_c = 0;
    my $output_c = 0;
    my $inout_c = 0;
    my @input_a = @$input_list_ref;
    my @output_a = @$output_list_ref;
    my @inout_a = @$inout_list_ref;

    open my $vfile, ">", $$top_name_ref.".v";
    print $vfile "module $$top_name_ref (\n";

    if (@$input_list_ref) {
        print $vfile "# input\n";
        for $in_ele (@$input_list_ref) {
            $input_c++;
            if (@$output_list_ref){
                print $vfile "\tinput\t\t\t\t$in_ele\t\t,\n";
            } else {
                if ($input_c == $#input_a+1) {
                    print $vfile "\tinput\t\t\t\t$in_ele\t\t\n";
                } else {
                    print $vfile "\tinput\t\t\t\t$in_ele\t\t,\n";
                }
            }  
        }
    }

    if (@$output_list_ref) {
        print $vfile "\n# output\n";
        for $out_ele (@$output_list_ref) {
            $output_c++;
            if (@$inout_list_ref){
                print $vfile "\toutput\t\t\t\t$out_ele\t\t,\n";
            } else {
                if ($output_c == $#output_a+1) {
                    print $vfile "\toutput\t\t\t\t$out_ele\t\t\n";
                } else {
                    print $vfile "\toutput\t\t\t\t$out_ele\t\t,\n";
                }
            }
        }
    }
    
    if (@$inout_list_ref) {
        print $vfile "\n# inout\n";
        for $io_ele (@$inout_list_ref) {
            $inout_c++;
            if ($inout_c == $#inout_a+1) {
                print $vfile "\tinout\t\t\t\t$io_ele\t\t\n";
            } else {
                print $vfile "\tinput\t\t\t\t$io_ele\t\t,\n";
            }
        }

    }
    
    print $vfile ");\n\n";
    my %all_wire_hash;

    for $name (@$mnarray) {
        for $key (keys %$phash) {
            my @port_array = @{$phash->{$key}};
            for $port (@port_array) {
                my @sp = split(/-/, $port);
                my $s = $sp[0];
                if (!($s =~ /^(input|output|inout)_top/)) {
                    if (!(exists $all_wire_hash{$s})){
                        $all_wire_hash{$s} = ();
                    }
                }
            }
        }
    }

    for $key (keys %all_wire_hash) {
        print $vfile ("wire\t\t\t\t", $key, "\t\t;\n");
    }
    print $vfile "\n\n";

    for $name (@$mnarray) {
        print $vfile ($name, " ", $name."_u", " (\n");
        for $key (keys %$phash) {
            if ($key eq 'input') {
                print $vfile "// input\n";
                my @port_array = @{$phash->{$key}};
                for $port (@port_array) {
                    my @sp = split(/-/, $port);
                    if ($sp[1] eq $name) {
                        my $s = $sp[0];
                        print $vfile "\t.$s\t\t\t\t($s)\t\t,\n";
                    }
                }
            } elsif ($key eq 'output') {
                print $vfile "// output\n";
                my @port_array = @{$phash->{$key}};
                for $port (@port_array) {
                    my @sp = split(/-/, $port);
                    if ($sp[1] eq $name) {
                        my $s = $sp[0];
                        print $vfile "\t.$s\t\t\t\t($s)\t\t,\n";
                    }
                }
            } elsif ($key eq 'inout') {
                print $vfile "// inout\n";
                my @port_array = @{$phash->{$key}};
                for $port (@port_array) {
                    my @sp = split(/-/, $port);
                    if ($sp[1] eq $name) {
                        my $s = $sp[0];
                        print $vfile "\t.$s\t\t\t\t($s)\t\t,\n";
                    }
                }
            }
        }
        my $pos = tell($vfile);
        seek($vfile, $pos - 2, 0);  # because of \n is the last , so back 2 byte
        truncate($vfile, tell($vfile));  

        print $vfile "\n);\n\n";
    }
     
    print $vfile "\nendmodule\n";

    close $vfile;
}


1;