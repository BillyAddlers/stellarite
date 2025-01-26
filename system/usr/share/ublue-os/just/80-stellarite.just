# vim: set ft=make :

# Install System Flatpaks (Support for Rebasing)
_install-system-flatpaks:
    #!/usr/bin/bash
    FLATPAK_LIST="$(curl https://raw.githubusercontent.com/BillyAddlers/stellarite/refs/heads/main/flatpaks | tr '\n' ' ')"
    flatpak --system -y install --or-update ${FLATPAK_LIST}

# Configure grub bootmenu visibility. pass action 'help' for more info.
configure-grub ACTION="":
    #!/usr/bin/bash
    source /usr/lib/ujust/ujust.sh
    # Function to display usage/help with some color
    print_help() {
      echo -e "Usage: ujust configure-grub <option>"
      echo
      echo -e "Where <option> can be:"
      echo -e "  ${bold}${cyan}hide${normal} = GRUB is hidden after a successful boot, even for dual-boot setups."
      echo -e "  ${bold}${yellow}unhide${normal} = GRUB is hidden after a successful boot, but it will show if dual-booting."
      echo -e "  ${bold}${green}show${normal} = GRUB always shows on boot."
      echo
      echo "If <option> is omitted, you will be prompted to choose interactively."
    }
    # Function to get the current GRUB menu_auto_hide setting and explain it
    get_current_setting() {
      local CURRENT_SETTING
      CURRENT_SETTING=$(sudo grub2-editenv - list | grep menu_auto_hide | cut -d= -f2)
      if [ -z "$CURRENT_SETTING" ]; then
        echo "Current GRUB menu_auto_hide setting: ${bold}${red}Not Set (default to 0)${normal}"
        echo "Explanation:"
        echo "  - ${bold}0${normal}: GRUB always shows on boot."
        return 0
      else
        case "$CURRENT_SETTING" in
          0)
            echo "Current GRUB menu_auto_hide setting: ${bold}${green}0 (Always Show)${normal}"
            echo "Explanation:"
            echo "  - ${bold}0${normal}: GRUB always shows on boot."
            ;;
          1)
            echo "Current GRUB menu_auto_hide setting: ${bold}${yellow}1 (Hide After Successful Boot)${normal}"
            echo "Explanation:"
            echo "  - ${bold}1${normal}: GRUB is hidden after a successful boot, but it will show if dual-booting."
            ;;
          2)
            echo "Current GRUB menu_auto_hide setting: ${bold}${cyan}2 (Always Hide)${normal}"
            echo "Explanation:"
            echo "  - ${bold}2${normal}: GRUB is hidden after a successful boot, even for dual-boot setups."
            ;;
          *)
            echo "Current GRUB menu_auto_hide setting: ${bold}${red}Unknown${normal}"
            echo "Explanation:"
            echo "  - This setting is unrecognized. Reset it to 0, 1, or 2."
            ;;
        esac
      fi
    }
    # Interactive menu for choosing the new behavior
    interactive_menu() {
      local options=(
        "Always Hide Grub (menu_auto_hide=2)"
        "Hide After Successful Boot (menu_auto_hide=1)"
        "Always Show Grub (menu_auto_hide=0)"
        "Exit without changes"
      )
      local choice
      choice=$(ugum choose "${options[@]}")
      echo "$choice"
    }
    # Function to apply the selected setting
    apply_setting() {
      local selected_option="$1"
      # Support the interactive strings as well as short commands
      case "$(echo "$selected_option" | tr '[:upper:]' '[:lower:]')" in
        *"(menu_auto_hide=2)"*|hide)
          sudo grub2-editenv - set menu_auto_hide=2
          echo "GRUB menu is now set to ${bold}${cyan}Always Hide${normal}."
          ;;
        *"(menu_auto_hide=1)"*|unhide)
          sudo grub2-editenv - set menu_auto_hide=1
          echo "GRUB menu is now set to ${bold}${yellow}Hide After Successful Boot${normal}."
          ;;
        *"(menu_auto_hide=0)"*|show)
          sudo grub2-editenv - set menu_auto_hide=0
          echo "GRUB menu is now set to ${bold}${green}Always Show${normal}."
          ;;
        *"exit without changes"*|exit)
          echo "${bold}No changes were made. Exiting...${normal}"
          ;;
        help)
          print_help
          ;;
        *)
          echo "${bold}${red}Invalid option selected. No changes were made.${normal}"
          ;;
      esac
    }
    OPTION="{{ ACTION }}"   # from “configure-grub ACTION=...”
    if [ "$OPTION" == "help" ]; then
      print_help
      exit 0
    fi
    get_current_setting
    echo
    # If no ACTION was passed, go interactive
    if [ -z "$OPTION" ]; then
      NEW_SETTING=$(interactive_menu)
      if [ -n "$NEW_SETTING" ]; then
        apply_setting "$NEW_SETTING"
      else
        echo "${bold}No changes were made.${normal}"
      fi
    else
      apply_setting "$OPTION"
    fi

# Add user to "input" group required by certain controller drivers
add-user-to-input-group:
    #!/usr/bin/bash
    if ! grep -q "input" /etc/group; then
      sudo bash -c 'grep "input" /lib/group >> /etc/group'
    fi
    sudo usermod -a -G input $USER

# Enable support for DisplayLink
enable-displaylink:
    systemctl enable --now displaylink.service

# Enable support for Tailscale
enable-tailscale:
    systemctl enable --now tailscaled.service

# Ptyxis terminal transparency
ptyxis-transparency opacity="0.95":
    #!/usr/bin/bash
    set -euxo pipefail
    if [[ -n "$(echo "{{ opacity }}" | grep -v '^[.0-9]*$')" ]]; then
      printf "Value must be numeric: %s.\n" "{{ opacity }}"
    elif [[ $(echo "0<{{ opacity }} && 1>={{ opacity }}" | bc -q) -eq 1 ]]; then
      raw="$(gsettings get org.gnome.Ptyxis profile-uuids)"
      uuids="$(sed -En 's|[^0-9a-z]*||g; s|([0-9a-z]{32})|\1\n|gp' <<<${raw})"
      for i in ${uuids}; do
        location="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/${i}/"
        gsettings set "${location}" opacity "{{ opacity }}"; done
      printf "Ptyxis opacity is now %s.\n" "{{ opacity }}"
    else
      printf "Value must be between 0 and 1: %s.\n" "{{ opacity }}"
    fi
