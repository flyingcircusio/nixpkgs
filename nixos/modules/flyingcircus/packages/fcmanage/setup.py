"""fcmanage

High-level system management scripts which are periodiacally called from
a systemd timer: update system configuration from an infrastructure
hydra server or from a local nixpkgs checkout.
"""

from setuptools import setup
from setuptools.command.test import test as TestCommand
import sys


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
        import pytest
        errno = pytest.main(self.pytest_args)
        sys.exit(errno)


setup(
    name='fc.manage',
    version='2.0',
    description=__doc__,
    url='https://flyingcircus.io',
    author='Christian Theune, Christian Kauhaus, Christian Zagrodnick',
    author_email='mail@flyingcircus.io',
    license='ZPL',
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'License :: OSI Approved :: Zope Public License',
        'Programming Language :: Python :: 3.4',
        'Topic :: System :: Systems Administration',
    ],
    packages=['fc.manage'],
    install_requires=[
        'fc.maintenance',
        'fc.util',
        'requests',
        'click',
    ],
    tests_require=['pytest', 'mock'],
    extras_require={'test': ['pytest', 'mock']},
    cmdclass={'test': PyTest},
    entry_points={
        'console_scripts': [
            'fc-manage=fc.manage.manage:main',
            'fc-monitor=fc.manage.monitor:main',
            'fc-resize=fc.manage.resize:main',
            'fc-graylog=fc.manage.input:cli',
        ],
    },
    zip_safe=False,
)
