# 📁 PowerShell Script Overview

This project contains **PowerShell scripts** to **automate** the administration of the **CyberArk PAM** solution via **REST APIs**.

## 🗂 Project Directory Structure  

📁 CyberArk-PAM-Automation  
│</br>
📁 scripts </br>
│    └── 🟦 main.ps1 </br>
│    └── 🟦 auth_handler.ps1 </br> 
│    └── 🟦 account_handler.ps1 </br>
│    └── 🟦 account_group_handler.ps1 </br>
│    └── 🟦 safe_handler.ps1 </br>
│    └── 🟦 safe_member_handler.ps1 </br>
│    └── 🟦 platform_handler.ps1 </br>
│    └── 🟦 connection_component_handler.ps1 </br>
│    └── 🟦 user_handler.ps1 </br>
│    └── 🟦 group_handler.ps1 </br>
│    └── 🟦 cpm_actions_handler.ps1 </br>
│    └── 🟦 system_health_handler.ps1 </br>
│    └── 🟦 log_handler.ps1 </br>
│</br>
📁 SampleCSVFiles </br>
│   └── 📂 SampleFileAccount </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_accounts_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_accounts_update.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_accounts_delete.csv </br>
│   └── 📂 SampleFileAccountGroup </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_account_groups_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_account_groups_members_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_account_groups_members_delete.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_account_groups_members_get.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_account_groups_by_safe.csv </br>
│   └── 📂 SampleFileSafe </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_update.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_delete.csv </br>
│   └── 📂 SampleFileSafeMember </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_members_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_members_delete.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_safes_members_update.csv </br>
│   └── 📂 SampleFilePlatform </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_platforms_import.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_platforms_export.csv </br>
│ │&emsp;&emsp;&nbsp; └──📂 Platform_ZipFile </br>
│ │&emsp;&emsp;&emsp;&emsp;&nbsp; └──📦 platform_to_import_name.zip **(one or more zip files)**</br>
│ │&emsp;&emsp;&nbsp; └──📂 Exported_Platform </br>
│ │&emsp;&emsp;&emsp;&emsp;&nbsp; └──📦 exported_platform__name.zip **(one or more zip files)**</br>
│   └── 📂 SampleFileConnectionComponent </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_connection_components_import.csv </br>
│ │&emsp;&emsp;&nbsp; └──📂 Connection_Component_ZipFile </br>
│ │&emsp;&emsp;&emsp;&emsp;&nbsp; └──📦 connection_component_to_import_name.zip **(one or more zip files)**</br>
│   └── 📂 SampleFileUser </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_update.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_delete.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_activate.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_enable.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_disable.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_users_reset_password.csv </br>
│   └── 📂 SampleFileGroup </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_groups_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_groups_update.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_groups_delete.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_groups_members_add.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_groups_members_remove.csv </br>
│   └── 📂 SampleFileCPMActions </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_verifypass.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_changepass_immediately.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_changepass_inVault.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_sample_changepass_specifyNextPass.csv </br>
│ │&emsp;&emsp;&nbsp; └──📄 sample_reconcilepass.csv </br>
│   └── 📂 SampleFileSystemHealth </br>
│  &emsp;&emsp;&nbsp;&nbsp; └──📄 sample_components.csv </br>
│</br>
📁 Documentation </br>
│    └── 📑 main.pdf </br>
│    └── 📑 auth.pdf </br> 
│    └── 📑 account.pdf </br>
│    └── 📑 account_group.pdf </br>
│    └── 📑 safe.pdf </br>
│    └── 📑 safe_member.pdf </br>
│    └── 📑 platform.pdf </br>
│    └── 📑 connection_component.pdf </br>
│    └── 📑 user.pdf </br>
│    └── 📑 group.pdf </br>
│    └── 📑 cpm_actions.pdf </br>
│    └── 📑 system_health.pdf </br>
│    └── 📑 log.pdf </br>
│ </br>
📁 Log </br>
│    └── 📄 log.log </br> 
│    └── 📄 error.log </br>
│</br>
└─────── 📝 README.md </br>


## 📄 File Description  

> ```
> 📦 platform_name.zip : Zip file containing the platform/connection component to import 
> 🟦 file_name.ps1     : PowerShell Script  
> 📄 file_name.csv     : CSV file, semicolon-separated, containing data used to execute actions 
> 📑 file_name.pdf     : This file explains the detailed description of each script’s purpose, the necessary permissions for execution, and the expected structure of the CSV files used as input.
> 📝 README.md         : This file explains the structure and usage of the project  
> ```

**This project is structured into multiple PowerShell scripts, each responsible for handling specific operations related to the PVWA API. Below is a detailed overview of each script and its responsibilities :**

---

#### 🔹 🔘 `main.ps1`
- **Purpose**: The main entry point of the project.
- **Functionality**: Displays the interactive menu and orchestrates all available actions by calling the corresponding handler scripts.

---

#### 🔹 `auth_handler.ps1`
- **Purpose**: Authentication handler.
- **Functionality**: Logs in to the PVWA, retrieves the authentication token for subsequent API requests, and handles logout to securely end the session.

---

#### 🔹 `account_handler.ps1`
- **Purpose**: Account management.
- **Functionality**: Add, update, delete, and list accounts stored in the vault.

---

#### 🔹 `account_group_handler.ps1`
- **Purpose**: Account group management.
- **Functionality**: Add account groups and list them by safe; add, delete, and retrieve members within account groups.

---

#### 🔹 `safe_handler.ps1`
- **Purpose**: Safe management.
- **Functionality**: Add, update, delete, and list safes.

---

#### 🔹 `safe_member_handler.ps1`
- **Purpose**: Safe member management.
- **Functionality**: Add, update, and delete members from safes.

---

#### 🔹 `platform_handler.ps1`
- **Purpose**: Platform management.
- **Functionality**: Import, export, retrieve details, and list all supported platforms.

---

#### 🔹 `connection_component_handler.ps1`
- **Purpose**: Connection component management.
- **Functionality**: List and import connection components.

---

#### 🔹 `user_handler.ps1`
- **Purpose**: User management.
- **Functionality**: Add, update, delete, enable/disable, activate, reset password, and list users.

---

#### 🔹 `group_handler.ps1`
- **Purpose**: Group management.
- **Functionality**: Add, update, delete groups, add and remove group members, and list all vault groups.

---

#### 🔹 `cpm_actions_handler.ps1`
- **Purpose**: Central Policy Manager (CPM) operations.
- **Functionality**: Perform credential verification, immediate change, in-vault change, change with a predefined password, and reconciliation.

---

#### 🔹 `system_health_handler.ps1`
- **Purpose**: System monitoring.
- **Functionality**: Retrieve summary and detailed monitoring data about system components (PVWA, CPM, PSM, etc.).

---

#### 🔹 `log_handler.ps1`
- **Purpose**: Logging operations.
- **Functionality**: Logs actions and errors to local files for debugging or auditing purposes.

## ▶️ Usage  

Run **PowerShell** in the parent directory **"CyberArk-PAM-Automation"** and then execute the following command:

```powershell
PowerShell -ExecutionPolicy Bypass -File .\main.ps1
```

## ℹ️ Additional Information on CyberArk REST APIs
For more details on the required and optional parameters for using CyberArk's REST APIs, please refer to the official [CyberArk REST API documentation](https://docs.cyberark.com/pam-self-hosted/latest/en/content/webservices/implementing%20privileged%20account%20security%20web%20services%20.htm).


##  Author
🧑‍💻 **[Ayoub RAKINE](https://linkedin.com/in/ayoub-rakine)**</br>
🏢 **NEVERHACK**</br>
</br>
©️2025
