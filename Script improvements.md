# Script Improvements

# Latest test results

## **Option 1 Install Prerequesites**: 
    Works as intended, but want to run commands silently with custom output for success/error messages. Needs the visual layout update.

## **Option 2 Deploy Core Server**:

### **arcane deployment**: 
    
    Files copied, variables replaced, docker compose up failed. Manually started the stack without errors. 
    
    Otherwise it works as intended. 
    
    It has been manually updated to achieve a specific visual layout. 
    
    Use this as a reference for the visual layout I want throughout.

## **Option 3 Deploy Additional Server**: 

    * Missing function call to deploy arcane

    * Dockge and Infrastructure stack deployed successfully.

    * Other stacks seem to have been copied correctly.

    * Fails to copy ssh key to core server and gives no specific error, skipping ssh setup and everything else completes without error. Related to conflicting info in known_hosts. May have to rethink this logic.

    * It seems to also have verbose output on by default, that's not right.

    * It needs the visual layout update.

## Visual Layout

    * Based on Option 2 styling

    * All lines begin with `‖` or the corresponding corner, 90, or tee symbol 

    * Text uses the format `‖  some text` with 2 spaces between ‖ and the text

    * The visual layout of the select an option promts have been converted to a horizontal layout and the Option input integrated into the visual layout.

### **Requires the visual layout update**

    * When running the script without manually creating/editing .env the way it prompts for values 

    * When the script warns that Option 3 requires an existing core server

    * When the script prompts for ssh keys

    * Any other place the script prompts the user


## **homepage config files**: 
    * replace placeholders with vars. 
    
    * Remove sections for remote server services. 
    
    * For services that run on multiple servers use the format service.server_hostname.domain (dockge, glances, dozzle, backrest, & duplicati)

## Future Plans

* Configure arcane using env for deployment, and hopefully after logging into arcane it will store the settings in the db, then I could comment out the env variables to re-enable webui configuration, restart the stack, and my default settings should persist but be modifiable in the webui. I hope it works that way, requires research and testing.

* Figure out requirements and how to configure arcane on every server with the environment of each server. So that user can manage any server via arcane from the webui of any of the servers.

* Develop a procedure for creating arcane templates from my copose files that will maintain the same functionality.

* Create arcane registry file for all services, hosted from the repo. The goal is to make the templates near 1-click installs from arcane. The templates should use .env.global as default variables (such as: puid, pgid, server_ip, domain, and many more).

