# function truncated_cwd {
#     if [[ $PWD == $HOME ]]; then
#         echo "~"
#     else
#         local dir=$(basename $PWD)
# #         # if dir is greater than 20 characters, truncate it and put two dots after it
#         if [[ ${#dir} -gt 20 ]]; then
#             echo "${dir:0:20}.."
#         else
#             echo $dir
#         fi
#     fi
# }

function truncated_cwd {
  if [[ $PWD == $HOME ]]; then
    echo "~"
  else
    local dir=$(basename $PWD)
    # Replace any name starting with 'shipper-integrations-' to 'si-<remainder>'
    if [[ $dir == shipper-integrations-* ]]; then
      dir="si-${dir#shipper-integrations-}"
    fi

    if [[ $dir == transporeon-* ]]; then
      dir="tpo-${dir#transporeon-}"
    fi

    if [[ $dir == uber-freight-* ]]; then
      dir="uf-${dir#uber-freight-}"
    fi

    if [[ $dir == shipment-* ]]; then
      dir="shpmnt-${dir#shipment-}"
    fi

    # If the resulting name is still over 20 chars, truncate and append ..
    if [[ ${#dir} -gt 20 ]]; then
      echo "${dir:0:20}.."
    else
      echo $dir
    fi
  fi
}

local ret_status="%(?:%{$fg_bold[green]%}➜:%{$fg_bold[red]%}➜)"

# Adjust the PROMPT variable to incorporate the truncated directory name
PROMPT='${ret_status}%{$fg[cyan]%}$(truncated_cwd)%{$reset_color%}$(git_prompt_info) '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%})%{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
 
# With day month and year
# PROMPT='%{$fg[yellow]%}[%D{%f/%m/%y} %D{%L:%M:%S}]'$PROMPT
 
# With time
# PROMPT='%{$fg[yellow]%}[%D{%L:%M:%S}]'$PROMPT
 
# With day and 24 hr time
PROMPT='%{$fg[yellow]%}%D{%f} %T'$PROMPT

