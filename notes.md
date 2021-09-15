# Terraform course notes

## Stale lock

If you receive message about a stale lock like below:

```
student12@Azure:~/clouddrive$ terraform plan
╷
│ Error: Error acquiring the state lock
│
│ Error message: state blob is already locked
│ Lock Info:
│ ID: d57dd381-95c7-3214-86bf-19022d5e4cb4
│ Path: tfstate/cprime.terraform.labs.tfstate
│ Operation: OperationTypeApply
│ Who: student12@cc-c571c01e-5764b8c6bb-8ngpd
│ Version: 1.0.6
│ Created: 2021-09-14 19:38:02.840342101 +0000 UTC
│ Info:
│
│
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended. 
```

You need to manually release the lock:

    terraform force-unlock [options] LOCK_ID [DIR]

or

    terraform force-unlock LOCK_ID

LOCK_ID should be in the message above.

(!) Note that you should check to ensure that no one else is using the lock!

## Troubleshooting

To "debug" Terraform, set the `TF_LOG` variable:

```sh
TF_LOG=TRACE terraform plan
```

Another reference: [Manipulating Terraform state](https://www.terraform.io/docs/cli/state/index.html)
