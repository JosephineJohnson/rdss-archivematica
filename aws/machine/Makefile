
.DEFAULT_GOAL := validate

validate:
	# Run ShellCheck to validate shell scripts
	@mkdir -p build/reports/shellcheck
	@for f in $$(ls *.sh **/*.sh) ; do \
		echo "Validating '$${f}' ... " ; \
		report_file="build/reports/shellcheck/$$(echo $${f} | tr '/' '_').txt" ;\
		docker run --rm \
			-v $$(pwd):/scripts \
			--workdir /scripts \
			koalaman/shellcheck -x -f gcc \
				$${f} | tee $${report_file} ; \
		if [ -s $${report_file} ] ; then \
			errors=$$(grep error: $${report_file} | wc -l) ; \
			notes=$$(grep note: $${report_file} | wc -l) ; \
			warnings=$$(grep warning: $${report_file} | wc -l) ; \
			echo "Validation failed for '$${f}'. $${errors} error(s), $${warnings} warning(s), $${notes} note(s)" ; \
			return 1 ; \
		else \
			echo "Validated '$${f}', all OK." ;\
		fi ;\
	done
