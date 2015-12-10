import smtplib

def send_email(from_addr, to_addrs, subject, body,
            throw_exception = False):
    try:
       # make to_addrs unique
       to_addrs = list(set(to_addrs))
       smtp = smtplib.SMTP('smtp.vmware.com')
       _body = '\r\n'.join(body)
       _headers = []
       _headers += ['X-VDNET-AUTOMAIL: True']
       _headers += ['From: %s' % from_addr]
       _headers += ['To: %s' % ','.join(to_addrs)]
       _headers += ['Subject: %s' % subject]
       _headers += ['']
       _headers += body
       smtp.sendmail(from_addr, to_addrs,'\r\n'.join(_headers))
    except smtplib.SMTPRecipientsRefused, e:
       # if recipient is not valid, then send to a known valid email address
       bad_addr_msg  = 'Unable to send email to original list of '\
                            'recipients.  These recipient email address(es)'\
                            ' were refused: %s\r\n\r\n'%to_addrs
       bad_addr_msg += 'The original email is shown below:\r\n'
       body.insert(0,  bad_addr_msg)
       #to_addrs = [backup_email_addr,]
       SendEmail(from_addr,to_addrs,subject,body)
       if throw_exception:
          raise e
    except Exception, e:
       if throw_exception:
          raise e

if __name__ == '__main__':
    send_email('gjayavelu@vmware.com', ['gjayavelu@vmware.com'], 'test', ['test'])

