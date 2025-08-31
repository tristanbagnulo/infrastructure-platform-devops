1. Log Into AWS Identity Center

* Go to the AWS Identity Center Console
* Make sure you’re signed into the management account where Identity Center is configured.

2. Go to Groups

* In the left-hand menu, click Groups.
Find the relevant group:
* For AdministratorAccess → Admin Access Group
* For Prod PowerUserAccess → Prod Infra Breakglass Access Group
* (Dev and Stage PowerUserAccess are handled automatically by the Platform Engineers group, so you usually won’t touch those.)

3. Add the User to the Group

* Click the group name.
* Go to the Users tab.
* Click Add users.
* In the Search users field, type the person’s name or email (this is their Identity Center username, not an IAM user).
* Tick the checkbox next to their name.
* Click Add users.
* Result:
    * The user is now a member of the group.
    * They immediately inherit the permission set(s) attached to that group.
    * The new role shows up in their AWS SSO Portal within ~1 minute.

4. User Log In

* User must log into the AWS SSO Portal.
* Find the relevant account.
* Select the new role (e.g. AdministratorAccess or Prod-PowerUserAccess).

5. Revoke Access Later

* When they no longer need elevated permissions:
    * Go back to AWS Identity Center → Groups.
    * Open the group you previously added them to.
    * On the Users tab, select their name.
    * Click Remove from group.

* Result:
    * The role disappears from their SSO portal immediately.
    * Any existing session will expire automatically based on the session duration you’ve set:
    * AdministratorAccess → 2 hours
    * Prod-PowerUserAccess → 2 hours