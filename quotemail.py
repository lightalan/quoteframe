#!/usr/bin/python3

import imaplib
import email
import time
import uuid
import email_credentials

def checkEmail():
    quotedir = "/home/pi/winshare/framequotes/quotes/"

    mail = imaplib.IMAP4_SSL('imap.gmail.com')
    mail.login(email_credentials.uid, email_credentials.pwd)
    #    mail.list()

    # Connect to inbox
    mail.select("inbox")
    
    # Search for email that meet our criteria
    result, data = mail.search(None, '(SUBJECT "Quote" UNSEEN FROM "' + email_credentials.adr +'")')


    ids = data[0]   # data is a list
    id_list = ids.split() # ids is a space separated string

    for id in id_list:
        latest_email_id = id
        result, data = mail.fetch(latest_email_id, "(RFC822)")
        raw_email = data[0][1]
        raw_email_string = raw_email.decode('utf-8')
        email_message = email.message_from_string(raw_email_string)
        subject = str(email.header.make_header(email.header.decode_header(email_message['Subject'])))

        for part in email_message.walk():
            if part.get_content_type() == "text/plain":
                body = part.get_payload(decode=False)
                u = str(uuid.uuid4())
                with open(quotedir+u+".txt", "w") as f:
                    print(body.strip(), file=f)
            else:
                continue
                
checkEmail()
