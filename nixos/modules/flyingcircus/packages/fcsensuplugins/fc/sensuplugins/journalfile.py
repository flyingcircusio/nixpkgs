"""Check the size of the journal file.

Files which are smaller than 500 bytes are considered to be defect.
"""

from glob import glob

import argparse
import logging
import nagiosplugin
import os.path

_log = logging.getLogger('nagiosplugin')


class JournalFile(nagiosplugin.Resource):

    def __init__(self):
        self.journal_file = glob('/var/log/journal/*/system.journal')[0]
        if not self.journal_file:
            return True

    def probe(self):
        size = os.path.getsize(self.journal_file)
        return nagiosplugin.Metric(
            self.journal_file, size, 'B', min=0, context='critical')


class JournalFileSummary(nagiosplugin.Summary):

    def ok(self, results):
        msg = []
        for r in results:
            msg.append('{}: {}'.format(r.metric.name, r.metric.value))
        return ', '.join(msg)

    def problem(self, results):
        msg = []
        for r in results.most_significant:
            msg.append('{}: {}'.format(r.metric.name, r.metric.valueunit))
        return ', '.join(msg)


@nagiosplugin.guarded
def main():
    a = argparse.ArgumentParser()
    a.add_argument('-c', '--critical', metavar='RANGE', default='500:',
                   help='return critical if file is smaller than RANGE')

    args = a.parse_args()
    check = nagiosplugin.Check(
        JournalFile(),
        nagiosplugin.ScalarContext('critical', critical=args.critical),
        JournalFileSummary())
    check.main()


if __name__ == '__main__':
    main()
