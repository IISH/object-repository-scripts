#!/usr/bin/env python
#
# sendmail.py
# Send a mail to an address


import getopt
import smtplib
import sys

# Import the email modules we'll need
from email.mime.text import MIMEText


def send(_body, _from, _to, _subject, _mail_relay, _mail_user, _mail_password):
    print('Attempting to send body ' +_body +
          ' from ' + _from +
          ' with subject ' + _subject +
          ' to ' + _to +
          ' via ' + _mail_relay)

    fp = open(_body, 'rb')
    msg = MIMEText(fp.read(), 'plain', 'utf8')
    fp.close()

    msg['Subject'] = _subject
    msg['From'] = _from
    msg['To'] = _to

    # Do not include the envelope header.
    s = smtplib.SMTP(_mail_relay)
    s.login(_mail_user, _mail_password)
    s.sendmail(_from, [_to], msg.as_string())
    s.quit()


def usage():
    print(
        'Usage: sendmail.py --b [body] --to [recipient] --from [sender] --subject [subject] --mail_relay [SMTP server]')


def main(argv):
    _body = _from = _to = _subject = _mail_relay = _mail_user = _mail_password = None

    try:
        opts, args = getopt.getopt(argv, 'hl:b:t:s:r:u:p:',
                                   ['help', 'body=', 'from=', 'to=', 'subject=', 'mail_relay=', 'mail_user=',
                                    'mail_password='])
    except getopt.GetoptError as e:
        print("Opt error: " + e.msg)
        usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        if opt in ('-b', '--body'):
            _body = arg
        elif opt in ('-f', '--from'):
            _from = arg
        elif opt in ('-t', '--to'):
            _to = arg
        elif opt in ('-s', '--subject'):
            _subject = arg
        elif opt in ('-r', '--mail_relay'):
            _mail_relay = arg
        elif opt in ('-u', '--mail_user'):
            _mail_user = arg
        elif opt in ('-p', '--mail_password'):
            _mail_password = arg

    assert _body
    assert _from
    assert _to
    assert _subject
    assert _mail_relay
    assert _mail_user
    assert _mail_password

    send(_body, _from, _to, _subject, _mail_relay, _mail_user, _mail_password)


if __name__ == '__main__':
    main(sys.argv[1:])