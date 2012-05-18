package Dist::Zilla::PluginBundle::DOY;
use Moose;
# ABSTRACT: Dist::Zilla plugins for me

use List::MoreUtils qw(any);

use Dist::Zilla;
with 'Dist::Zilla::Role::PluginBundle::Easy';

=head1 SYNOPSIS

  # dist.ini
  [@DOY]
  dist = Dist-Zilla-PluginBundle-DOY
  repository = github

=head1 DESCRIPTION

My plugin bundle. Roughly equivalent to:

    [Prereqs / TestMoreDoneTesting]
    -phase = test
    -type = requires
    Test::More = 0.88

    [GatherDir]
    [PruneCruft]
    [ManifestSkip]
    [MetaYAML]
    [License]
    [Readme]
    [RunExtraTests]
    [ExecDir]
    [ShareDir]
    [MakeMaker]
    [Manifest]

    [TestRelease]
    [ConfirmRelease]

    [MetaConfig]
    [MetaJSON]

    [NextRelease]
    format = %-5v %{yyyy-MM-dd}d
    [CheckChangesHasContent]

    [PkgVersion]
    [Authority]
    authority = cpan:DOY

    [PodCoverageTests]
    [PodSyntaxTests]
    [NoTabsTests]
    [EOLTests]
    [Test::Compile]

    [MetaResources]
    ; autoconfigured, based on the value of 'repository'

    [Git::Check]
    allow_dirty =
    [Git::Commit]
    commit_msg = changelog
    [Git::Tag]
    tag_format = %v
    tag_message =
    [Git::NextVersion]
    version_regexp = ^(\d+\.\d+)$
    first_version = 0.01

    [PodWeaver]

    [UploadToCPAN]

=cut

has dist => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has authority => (
    is      => 'ro',
    isa     => 'Str',
    default => 'cpan:DOY',
);

has github_user => (
    is      => 'ro',
    isa     => 'Str',
    default => 'doy',
);

has github_name => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { lc shift->dist },
);

has repository => (
    is  => 'ro',
    isa => 'Str',
);

for my $attr (qw(repository_type repository_url repository_web)) {
    has $attr => (
        is      => 'ro',
        isa     => 'Maybe[Str]',
        lazy    => 1,
        default => sub {
            my $self = shift;
            my $data = $self->_repository_data;
            return unless $data;
            return $data->{$attr};
        },
    );
}

sub _repository_data {
    my $self = shift;

    my $host = $self->repository;
    return unless defined $host;

    die "Unknown repository host $host"
        unless exists $self->_repository_host_map->{$host};

    return $self->_repository_host_map->{$host};
}

has _repository_host_map => (
    is      => 'ro',
    isa     => 'HashRef[HashRef[Str]]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return {
            'github' => {
                repository_type => 'git',
                repository_url  => sprintf('git://github.com/%s/%s.git', $self->github_user, $self->github_name),
                repository_web  => sprintf('https://github.com/%s/%s', $self->github_user, $self->github_name),
            },
            'gitmo' => {
                repository_type => 'git',
                repository_url  => sprintf('git://git.moose.perl.org/%s.git', $self->dist),
                repository_web  => sprintf('http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/%s.git;a=summary', $self->dist),
            },
        }
    },
);

has bugtracker_web => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        sprintf('http://rt.cpan.org/Public/Dist/Display.html?Name=%s',
                shift->dist);
    },
);

has bugtracker_mailto => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { sprintf('bug-%s@rt.cpan.org', lc shift->dist); },
);

has homepage => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { sprintf('http://metacpan.org/release/%s', shift->dist) },
);

has awesome => (
    is  => 'ro',
    isa => 'Str',
);

has dynamic_config => (
    is  => 'ro',
    isa => 'Str',
);

has is_task => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { shift->dist =~ /^Task-/ ? 1 : 0 },
);

has is_test_dist => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return 1 if $ENV{DZIL_FAKE_RELEASE};
        return $self->dist =~ /^Foo-/ ? 1 : 0
    },
);

has _plugins => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    default => sub {
        my $self = shift;
        [
            qw(
                GatherDir
                PruneCruft
                ManifestSkip
                MetaYAML
                License
                Readme
                RunExtraTests
                ExecDir
                ShareDir
            ),
            ($self->awesome ? $self->awesome : 'MakeMaker'),
            qw(
                Manifest
                TestRelease
                ConfirmRelease
                MetaConfig
                MetaJSON
                NextRelease
                CheckChangesHasContent
                PkgVersion
                Authority
                PodCoverageTests
                PodSyntaxTests
                NoTabsTests
                EOLTests
                Test::Compile
                Metadata
                MetaResources
                Git::Check
                Git::Commit
                Git::Tag
                Git::NextVersion
            ),
            ($self->is_task      ? 'TaskWeaver'  : 'PodWeaver'),
            ($self->is_test_dist ? 'FakeRelease' : 'UploadToCPAN'),
        ]
    },
);

has plugin_options => (
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    init_arg => undef,
    lazy     => 1,
    default  => sub {
        my $self = shift;
        my %opts = (
            'NextRelease'        => { format => '%-5v %{yyyy-MM-dd}d' },
            'Authority'          => { authority => $self->authority },
            'Git::Check'         => { allow_dirty => '' },
            'Git::Tag'           => { tag_format => '%v', tag_message => '' },
            'Git::NextVersion' => {
                version_regexp => '^(\d+\.\d+)$',
                first_version  => '0.01'
            },
            'Git::Commit' => {
                commit_msg => 'changelog',
            },
        );

        $opts{Metadata} = {
            dynamic_config => 1,
        } if $self->dynamic_config;

        for my $metaresource (qw(repository.type repository.url repository.web bugtracker.web bugtracker.mailto homepage)) {
            (my $method = $metaresource) =~ s/\./_/g;
            my $value = $self->$method;
            if (!$value) {
                warn "*** resources.$metaresource is not configured! This needs to be fixed! ***";
                next;
            }
            $opts{MetaResources}{$metaresource} = $value;
        }
        delete $opts{MetaResources}{'repository.type'}
            unless exists $opts{MetaResources}{'repository.url'};

        for my $option (keys %{ $self->payload }) {
            next unless $option =~ /^([A-Z][^_]*)_(.+)$/;
            my ($plugin, $plugin_option) = ($1, $2);
            $opts{$plugin} ||= {};
            $opts{$plugin}->{$plugin_option} = $self->payload->{$option};
        }

        return \%opts;
    },
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $args = $class->$orig(@_);
    return { %{ $args->{payload} }, %{ $args } };
};

sub configure {
    my $self = shift;

    $self->add_plugins(
        [ 'Prereqs' => 'TestMoreDoneTesting' => {
            -phase       => 'test',
            -type        => 'requires',
            'Test::More' => '0.88',
        } ]
    );
    $self->add_plugins(
        map { [ $_ => ($self->plugin_options->{$_} || {}) ] }
            @{ $self->_plugins },
    );
}

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-dist-zilla-pluginbundle-doy at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dist-Zilla-PluginBundle-DOY>.

=head1 SEE ALSO

L<Dist::Zilla>

L<Task::BeLike::DOY>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Dist::Zilla::PluginBundle::DOY

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-DOY>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-DOY>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-DOY>

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-DOY>

=back

=begin Pod::Coverage

  configure

=end Pod::Coverage

=cut

__PACKAGE__->meta->make_immutable;
no Moose;

1;
