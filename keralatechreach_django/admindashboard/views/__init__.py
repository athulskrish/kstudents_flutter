# This file makes the views directory a proper Python package
from .dashboard import *
from .academic import *
from .content import *
from .users import register, profile, user_list, user_detail, user_delete
from .jobs import job_list, job_create, job_edit, job_delete
from .contact_messages import contact_messages, contact_message_detail, contact_message_delete 