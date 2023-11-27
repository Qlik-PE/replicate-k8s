$comma = q();              # Will become a comma
for (<>) {
    next if /^\s*#/;       # Comment?
    if (/license_type=/) { # Looks like a license file?}
        $license=1;
        print qq({\n\t"cmd.license":\t{);  # Open up the JSON structure
    }
    next unless $license and /=/;
    chomp;                 # Remove New-line
    s/=/":"/;
    print qq(${comma}\n\t\t"${_}");
    $comma = q(,);         # Now it must become real
}
print qq(\n\t}\n}\n);      # And close the JSON structure
