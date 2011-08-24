package Cole;

use strict;
use warnings;

our $VERSION = '0.009001';

require Carp;

use Class::Load  ();
use Scalar::Util ();

sub new {
    my $class = shift;

    my $self = {@_};
    bless $self, $class;

    return $self;
}

sub register {
    my $self = shift;
    my $key  = shift;

    Carp::croak('Service name is required') unless $key;

    if (@_ == 1 && !(ref($_[0]) eq 'HASH')) {
        my $type =
            Scalar::Util::blessed($_[0]) ? 'instance'
          : ref($_[0]) eq 'CODE' ? 'block'
          :                        'constant';
        $self->{services}->{$key}->{$type} = $_[0];
        return $self;
    }

    $self->{services}->{$key} = @_ == 1 ? $_[0] : {@_};

    return $self;
}

sub get {
    my $self = shift;
    my ($key) = @_;

    my $service = $self->_get($key);

    if (exists $service->{instance}) {
        return $service->{instance};
    }
    elsif (exists $service->{block}) {
        my %args = $self->_build_deps($service);
        return $service->{block}->($self, %args);
    }

    if ($service->{lifecycle} && $service->{lifecycle} eq 'prototype') {
        return $self->_build_service($service);
    }

    return $service->{instance} = $self->_build_service($service);
}

sub get_all {
    my $self = shift;

    my @services;
    foreach my $service (keys %{$self->{services}}) {
        push @services, $service => $self->get($service);
    }

    return @services;
}

sub _get {
    my $self = shift;
    my ($key) = @_;

    die "Service '$key' does not exist"
      unless exists $self->{services}->{$key};

    return $self->{services}->{$key};
}

sub _build_service {
    my $self = shift;
    my ($service) = @_;

    return $service->{constant} if exists $service->{constant};

    Class::Load::load_class($service->{class});

    my %args = $self->_build_deps($service);

    return $service->{class}->new(%args);
}

sub _build_deps {
    my $self = shift;
    my ($service) = @_;

    if (my $deps = $service->{deps}) {
        $deps = [$deps] unless ref $deps eq 'ARRAY';

        my %args;
        foreach my $dep (@$deps) {
            my ($key, $value) = ($dep, $dep);

            if (ref $dep eq 'HASH') {
                $key   = (keys(%$dep))[0];
                $value = (values(%$dep))[0];
            }

            $args{$key} = $self->get($value);
        }

        return %args;
    }

    return ();
}

1;
__END__

=head1 NAME

Cole - Lightweight DI container

=head1 SYNOPSIS

    $ioc = Cole->new;

    $ioc->register('class name', class => 'Foo');
    $ioc->register('string',     'Hello, world!');
    $ioc->register('instance',   Foo->new);

    $ioc->register('dependency', class => 'Bar', deps => 'foo');
    $ioc->register(
        'multiple dependencies',
        class => 'Baz',
        deps  => ['foo', 'bar']
    );

=head1 DESCRIPTION

L<Cole> is a lightweight Dependency Injection container.

=head1 FEATURES

=head2 C<Constants>

    $ioc->register('string' => 'Hello world!');

=head2 C<Class names>

    $ioc->register('class' => {class => 'Foo'});

=head2 C<Instances>

    $ioc->register('class' => Foo->new);

=head2 C<Dependencies>

    $ioc->register('class' => {class => 'Foo', deps => 'bar'});

=head2 C<Aliases>

    $ioc->register('class' => {class => 'Foo', deps => {'bar' => 'baz'}});

C<bar> is passed as C<baz> during C<Foo> creation.

=head1 METHODS

=head2 C<new>

    my $ioc = Cole->new;

=head2 C<register>

    $ioc->register('name' => {class => 'foo'});

Register a new dependency.

=head2 C<get>

    $ioc->get('name');

Return an instance of a service by name.

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/cole

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
