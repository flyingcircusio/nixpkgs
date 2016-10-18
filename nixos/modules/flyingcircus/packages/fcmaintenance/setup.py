"""Maintenance request management."""

from setuptools import setup
from setuptools.command.test import test as TestCommand
from codecs import open
from os import path
import sys

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.rst'), encoding='ascii') as f:
    long_description = f.read()

test_req = ['pytest', 'pytest-catchlog', 'freezegun']


class PyTest(TestCommand):
    user_options = [('pytest-args=', 'a', "Arguments to pass to py.test")]

    def initialize_options(self):
        TestCommand.initialize_options(self)
        self.pytest_args = []

    def finalize_options(self):
        TestCommand.finalize_options(self)
        self.test_args = []
        self.test_suite = True

    def run_tests(self):
        # import here, cause outside the eggs aren't loaded
        import pytest
        errno = pytest.main(self.pytest_args)
        sys.exit(errno)


setup(
    name='fc.maintenance',
    version='2.0',
    description=__doc__,
    long_description=long_description,
    url='https://github.com/flyingcircus/nixpkgs',
    author='Christian Kauhaus',
    author_email='kc@flyingcircus.io',
    license='ZPL',
    classifiers=[
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],
    packages=['fc.maintenance', 'fc.maintenance.lib'],
    install_requires=['fc.util', 'pytz', 'shortuuid', 'iso8601', 'PyYAML'],
    tests_require=test_req,
    cmdclass={'test': PyTest},
    extras_require={
        'dev': test_req + ['pytest-cov'],
        'test': test_req,
    },
    zip_safe=False,
    entry_points={
        'console_scripts': [
            'fc-maintenance=fc.maintenance.reqmanager:main',
            'list-maintenance=fc.maintenance.reqmanager:list_maintenance',
            'scheduled-script=fc.maintenance.lib.shellscript:main',
            'scheduled-reboot=fc.maintenance.lib.reboot:main',
        ],
    },
)
