#!/usr/bin/env bash

ARCHIVE_BRANCH='archive'
SOFTWARE_HERITAGE='true'

init_git() {
	git config --global user.name 'github-actions[bot]'
	git config --global user.email 'github-actions[bot]@users.noreply.github.com'
	git checkout --orphan "$ARCHIVE_BRANCH"
	find . -not -name '*.bundle' -not -name './.git' -not -path './.git' -not -path './.git/*' -exec git rm -rf "{}" \;
	git pull origin "$ARCHIVE_BRANCH"
}

repo_exist_not_empty() {
	local url ref
	url="$1"
	ref="$2"

	(git ls-remote --quiet --exit-code --heads "$url" | grep --max-count 1 "refs/heads/$ref") &>/dev/null
	return $?
}

is_comment() {
	if [[ "$1" =~ ^\s*[#](.*)$ ]]; then
		return 0
	else
		return 1
	fi
}

url_exist() {
	http_code="$(curl --silent --output /dev/null --write-out "%{http_code}\n" "$1")"
	if [ "$http_code" = '200' ]; then
		return 0
	else
		return 1
	fi
}

# Usage: add_to_readme <url> <name>
add_to_readme() {
	local repo_url repo_name
	repo_url="$1"
	repo_name="$2"

	# If no readme
	if [ ! -s README.md ]; then
		echo -e '# CodeStreisand

<details><summary>How to restore</summary>

## General instructions

1. Clone the `archive` branch

```bash
git clone --branch archive https://github.com/your-username/your-repo codestreisand
```

2. Restore from bundle

```bash
git clone codestreisand/FILE.bundle
```

## Download only a specific backup

```bash
git clone --no-checkout --depth=1 --no-tags --branch archive https://github.com/your-username/your-repo codestreisand
git -C codestreisand restore --staged FILE.bundle
git -C codestreisand checkout FILE.bundle
git clone codestreisand/FILE.bundle
```

</details>

| Status | Name | Software Heritage | Last Update |
| - | - | - | - |' >>README.md
	fi

	# Check Software Heritage
	software_heritage_md='Not available'
	if url_exist "$repo_url"; then
		software_heritage_md="[Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=$repo_url)"
	fi

	# If not in readme
	if ! grep --silent "$repo_url" README.md; then
		current_date="$(date '+%d/%m/%Y')"
		if url_exist "$repo_url"; then
			echo "| 🟩 | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >>README.md
		elif [ -s "$repo_name.bundle" ]; then
			echo "| 🟨 | [$repo_name]($repo_url) | $software_heritage_md | $current_date |" >>README.md
		else
			echo "| 🟥 | [$repo_name]($repo_url) | $software_heritage_md | never |" >>README.md
		fi
	fi
}

# Usage: update_repo_date <repo url>
update_repo_date() {
	local repo_url
	repo_url="$1"

	current_date="$(date '+%d/%m/%Y')"
	awk --assign url="$repo_url" --assign date="$current_date" 'BEGIN {FS=OFS="|"} $3 ~ url {$5=" "date" "} 1' README.md >README.md.temp && mv --force README.md.temp README.md
}

# Usage: set_repo_status <repo url> <repo name>
set_repo_status() {
	local repo_url repo_name color
	repo_url="$1"
	repo_name="$2"
	color=''

	if url_exist "$1"; then
		color='🟩'
	elif [ -s "$2.bundle" ]; then
		color='🟨'
	else
		color='🟥'
	fi

	awk --assign url="$repo_url" --assign status="$color" 'BEGIN {FS=OFS="|"} $3 ~ url {$2=" "status" "} 1' README.md >README.md.temp && mv --force README.md.temp README.md
	[ "$repo_name" = 'test-repo' ] && cat README.md
}

# Usage: commit_and_push <repo name>
commit_and_push() {
	local repo_name
	repo_name="$1"

	git add README.md
	git add "$repo_name.bundle" >/dev/null 2>&1
	git commit --message="Update $repo_name" >/dev/null 2>&1
	git push origin "$ARCHIVE_BRANCH" >/dev/null 2>&1
}

list="$(cat list.txt)"
init_git
while IFS= read -r entry; do
	if [ -n "$entry" ] && ! is_comment "$entry"; then
		repo_name="$(basename "$entry")"
		echo -e "\n\n---------------------------- Archiving ${repo_name}... ----------------------------\n\n"

		# Save the current bundle hash
		current_hash=''
		if [ -s "$repo_name.bundle" ]; then
			current_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
		fi

		# Create a bundle
		if repo_exist_not_empty "$entry"; then
			git clone --mirror --recursive -j8 "$entry" "$repo_name"
			git -C "$repo_name" bundle create "../$repo_name.bundle" --all
			rm -rf "$repo_name"
		fi

		add_to_readme "$entry" "$repo_name"
		set_repo_status "$entry" "$repo_name"

		# Save the new bundle hash
		new_hash='default_value'
		if [ -s "$repo_name.bundle" ]; then
			new_hash="$(sha256sum "$repo_name.bundle" | awk '{print $1}')"
		fi

		# If the bundle changed
		if [ "$new_hash" != "$current_hash" ]; then

			# If a the bundle was updated
			if [ "$new_hash" != 'default_value' ]; then
				update_repo_date "$entry"
			fi

			# Post to Software Heritage
			if [ "$SOFTWARE_HERITAGE" = 'true' ]; then
				response="$(curl --request POST "https://archive.softwareheritage.org/api/1/origin/save/git/url/$entry/" | jq --raw-output .save_request_status)"
				echo "Software Heritage: $response"
			fi
		fi
		commit_and_push "$repo_name"
	fi
done <<<"$list"
