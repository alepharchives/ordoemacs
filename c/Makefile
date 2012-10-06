OBJS = rules_agenda.o rules_lhs_analysis.o core_function_args.o func_math.o \
 	core_oo.o core_oo_query.o core_oo_class_def.o core_oo_meta.o core_oo_class_init.o \
 	parser_class.o parser_class_member.o core_repl.o core_constructs.o core_bindings.o \
 	core_constraints.o rules_conflict_resolution.o core_constructs_meta.o parser_construct.o \
 	core_constraints_query.o core_constraints_ops.o parser_constraint.o \
 	core_constraints_default.o core_oo_instances_def.o mop.o func_facts.o \
 	rules_facts_def.o parser_facts.o \
 	core_functions.o core_functions_def.o parser_function.o rules_join.o \
 	func_math_ext.o func_overload.o \
 	rules_engine.o core_environment.o core_eval.o core_expressions.o core_expressions_meta.o \
 	parser_expression.o core_functions_ext.o rules_pattern_build.o func_assertions.o \
 	func_facts_query.o rules_facts_gen.o rules_facts_hash.o rules_lhs.o rules_matching.o rules_facts_manager.o \
 	rules_facts_util.o parser_fact_query.o func_facts_mod.o rules_rete.o rules_rhs.o func_loading.o \
 	rules_join_constraint_gen.o func_generic.o core_generics.o core_generics_meta.o \
 	parser_generic.o parser_implicit_method.o rules_incremental_reset.o parser_inheritance.o \
 	func_instance.o func_instance_loading.o core_oo_instances_meta.o core_oo_instances_manager.o func_instance_mod.o \
 	parser_instance.o mop_oo_instance.o parser_instance_query.o func_io.o rules_logical_dep.o main.o \
 	core_gc_alloc.o func_meta.o func_module.o core_ns.o \
 	parser_module.o core_ns_meta.o func_message.o core_oo_messages_meta.o core_oo_messages.o parser_message.o \
 	type_list.o func_list.o rules_oo.o \
 	rules_oo_meta.o rules_oo_gen.o rules_oo_matching.o func_parse_function.o rules_pattern.o \
 	pp.o core_procedures.o func_flow_control.o parser_flow_control.o func_predicate.o core_print.o \
 	ext_profile.o rules_lhs_reorder.o rules_rete_meta.o rules_retract.o core_router.o \
 	rules_join_network.o func_rule_def.o func_rule.o rules_constraints.o rules_def.o \
 	rules_delete.o parser_rule_lhs.o parser_rule.o core_scanner.o func_sort.o func_string.o \
 	type_atom.o sysdep.o parser.o \
 	rules_template_def.o rules_template.o func_template.o parser_template_lhs.o \
 	parser_template.o parser_template_rhs.o rules_template_meta.o ext_data.o ext_func.o core_gc.o ext_watch.o \
 	edmain.o edbasic.o edmisc.o edstruct.o edterm.o

.c.o :
	gcc -c -Wall  -Wundef -Wpointer-arith -Wshadow -Wcast-qual \
	    -Wcast-align -Winline -Wmissing-declarations -Wredundant-decls \
	    -Wmissing-prototypes -Wnested-externs \
	    -Wstrict-prototypes -Waggregate-return -Wno-implicit $<

pre_ix : pre_setup $(OBJS)
	gcc -o ix $(OBJS)  -lm -ltermcap   

pre_setup :
	sed "s/%%LANGUAGE%%/PRE_IX/g" setup.tmpl > setup.h

ix : ix_setup $(OBJS) 
	gcc -o ix $(OBJS)  -lm -ltermcap   
	
ix_setup :
	sed "s/%%LANGUAGE%%/IX/g" setup.tmpl > setup.h

# Dependencies generated using "gcc -MM *.c"
