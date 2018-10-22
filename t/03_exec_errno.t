
use Test::More tests => 11;

use File::Temp;

use Errno;

use Proc::FastSpawn;

{
    note "a failing process";

    my $tempdir = File::Temp::tempdir( CLEANUP => 1 );

    symlink 'foo', "$tempdir/foo";
    do { open my $f, '>', "$tempdir/file" };

    local ( $?, $! );

    my @t = (
        [ ENAMETOOLONG => "x" x 10000 ],
        [ ENOENT => 'nonexistent.' . substr( rand, 2 ) ],
        [ ELOOP => 'foo' ],
        [ ENOTDIR => 'file/haha' ],
    );

    for my $t ( @t ) {
        my ($expect_err, $name) = @$t;

        my $pid = spawn "$tempdir/$name", [ "$tempdir/$name" ];

      SKIP: {
            skip "Failed to fork(): $!" if !$pid;

            my $err = $!;

            ok $pid, "pid $pid";
            waitpid( $pid, 0 );

            is 0 + $err, Errno->can($expect_err)->(), "\$! reflects errno from execve ($expect_err)";
        }
    }
}

{
    local ( $?, $! );

    note "a working process";
    my $pid = spawn $^X, [ "perl", "-e", "print qq[# print from kid: abcd\n];" ];
    if ($pid) {
        my $err = $!;

        ok $pid, "pid $pid";
        waitpid( $pid, 0 );

        is $?, 0, q[$? is not set];

        note '$?: ', $?;
        note '$!: ', $!;

        is 0 + $err, 0, '$! is unset';
    }
}
