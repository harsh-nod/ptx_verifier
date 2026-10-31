"""Project audited original-vector reports to public data; no verifier execution.

Example: python3 publish_vector_comparison.py --reports RUNS --builds BUILDS \
  --audit independent-audit.json --output vector-comparison.json
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

STATES = ['verified', 'graph_rejected', 'unsupported']
IDENTITY = ['id','kernel','dtype','rt_shape','size_multiplier','workers','layout','elements']
EXPECTED = {'previous':'0e634bc43536e5e4ac5cb13e8046d8e1edd57250',
            'candidate':'90e172f3349c89c1d5ccbd8f1db21c312cb2bc10'}
NAMES = {'copy':('vectors',252), 'vec-add1':('vec-add1',84)}


def require(ok, message):
    if not ok:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def hfile(path):
    return sha(Path(path).read_bytes())


def read(path):
    return json.loads(Path(path).read_text())


def relative_source(path):
    require(isinstance(path,str) and not Path(path).is_absolute() and '..' not in Path(path).parts,
            'expected repository-relative source path')
    return path


def counts(values):
    result = Counter(values)
    require(not set(result)-set(STATES), 'unrecognized disposition')
    return {key:result[key] for key in STATES}


def build_record(path, revision):
    value = read(path)
    require(value['revision']==revision and value['trust']=='caller_attested'
            and value['source_clean'] is True and value['profile']=='release'
            and value['default_features'] is True and value['features']==[]
            and value['command']==['cargo','build','--release','-p','volta_cli'],
            'unexpected audited build profile')
    return {key:value[key] for key in ['revision','trust','source_clean','profile','features',
            'default_features','command','binary_sha256','rust_workspace_fingerprint','rustc','cargo']} | {
            'build_record_sha256':hfile(path)}


def transcript(directory, case, name, report_record):
    root = directory/case['id']
    path = root/(name+'.json')
    record = read(path)
    require(record==report_record, 'process record differs from report')
    stdout_path, stderr_path = root/(name+'.stdout'), root/(name+'.stderr')
    stdout = stdout_path.read_text()
    properties = re.findall(r'^  (AMD .*?) \([^\n)]*\)\s+(PASS|FAIL|UNKNOWN)$',stdout,re.M)
    require(len(properties)==len(dict(properties))==4, 'four distinct properties required')
    verdict = re.findall(r'^VERDICT: (ACCEPT|REJECT|UNKNOWN)$',stdout,re.M)
    compared = re.findall(r'^VC check:.*  elements: (\d+)(?:/(\d+))?$',stdout,re.M)
    require(len(verdict)==1 and len(compared)<=1 and (not compared or compared==[(str(case['elements']),'')]),
            'unrecognized result cardinality')
    pair_rows = re.findall(r'^      MemoryConflict \{ kind: (\w+), location: ByteLocation \{ space: (\w+), addr: (\d+) \}, earlier: EventId\((\d+)\), later: EventId\((\d+)\) \}$',stdout,re.M)
    pairs = [{'kind':kind,'space':space,'byte_address':int(addr),'earlier_event':int(a),'later_event':int(b)}
             for kind,space,addr,a,b in pair_rows]
    extra = re.findall(r'^      \.\.\. \((\d+) more\)$',stdout,re.M)
    mismatch = re.findall(r'^NOT EQUIVALENT: (\d+) mismatched element\(s\) vs spec$',stdout,re.M)
    instructions = re.findall(r'^Exec:.*  instructions: (\d+)  block syncs:',stdout,re.M)
    require(len(extra)<=1 and len(mismatch)<=1 and len(instructions)==1, 'ambiguous numeric diagnostics')
    return {'process_status':record['status'],'returncode':record['returncode'],
            'properties':dict(properties),'verdict':verdict[0],
            'compared_elements':int(compared[0][0]) if compared else None,
            'mathematically_equivalent':'EQUIVALENT (matches spec)' in stdout and 'NOT EQUIVALENT' not in stdout,
            'mismatched_elements':int(mismatch[0]) if mismatch else None,
            'executed_instructions':int(instructions[0]),
            'printed_memory_conflicts':pairs,
            'memory_conflict_count':len(pairs)+sum(map(int,extra)),
            'record_sha256':hfile(path),'stdout_sha256':hfile(stdout_path),
            'stderr_sha256':hfile(stderr_path),
            'command_sha256':sha(json.dumps(record['command'],separators=(',',':')).encode())}


def report_profile(directory, report, role, audit):
    summary = audit['reports'][directory.name]
    require(hfile(directory/'report.json')==summary['raw_report_sha256'], 'report differs from independently audited bytes')
    require(report['binary_revision']==EXPECTED[role], 'wrong variant revision')
    require(report['timeout_seconds']==60, 'changed execution budget')
    inputs = report['input_sha256']
    artifact = report['results'][0]['stage']['command']
    assembly = Path(artifact[artifact.index('verify')+1])
    require(hfile(assembly)==inputs['assembly'] and hfile(assembly.parent/'kernel.o')==inputs['object'],
            'whole module or object changed')
    controls = []
    for control in report['mathematical_controls']:
        case = next(r for r in report['results'] if r['id']==control['case'])
        controls.append({k:control[k] for k in ['case','status','passed','original_graph_status','math_refuted','graph_verified'] if k in control} | {
            'process':transcript(directory,case,'wrong-spec',control['stage'])})
    totals = {'outcomes':counts(r['status'] for r in report['results']),
              'full_specifications':sum(r['full_specification_proved'] for r in report['results']),
              'full_output_coordinates':sum(r['elements'] for r in report['results'] if r['full_specification_proved']),
              'by_dtype':{dtype:{'outcomes':counts(r['status'] for r in report['results'] if r['dtype']==dtype),
                  'full_specifications':sum(r['full_specification_proved'] for r in report['results'] if r['dtype']==dtype)}
                  for dtype in sorted({r['dtype'] for r in report['results']})}}
    require(totals['full_output_coordinates']==summary['full_output_coordinates'], 'math count drift')
    return {'raw_report_sha256':hfile(directory/'report.json'),'pre_run_identity_sha256':hfile(directory/'identity.json'),
            'case_inventory_sha256':hfile(directory/'cases.json'), 'input_sha256':inputs,
            'source':relative_source(report['source']),
            'source_sha256':{relative_source(p):h for p,h in report['source_sha256'].items()},
            'spec_sha256':report['spec_sha256'],'wrong_spec_sha256':report['wrong_spec_sha256'],
            'original_compile_record_sha256':hfile(assembly.parent/'compile.json'),
            'original_assemble_record_sha256':hfile(assembly.parent/'assemble.json'),
            'layout_source_sha256':hfile(directory/'layout-check.cpp'),
            'layout_record_sha256':hfile(directory/'layout-check.json'),
            'original_metadata':{'target':'gfx950','wave_size':64,'static_lds_bytes':0,'kernarg_bytes':32,
                'parameters':[{'offset':0,'size':16,'value_kind':'by_value'},{'offset':16,'size':16,'value_kind':'by_value'}]},
            'summary':totals,'negative_controls':controls}


def project(args):
    audit = read(args.audit)
    require(audit['result']=='pass' and not audit['errors'] and audit['checks']>0, 'independent raw audit must pass')
    result = {'schema_version':1,
        'scope':'Functional-only comparison of all original 252 CDNA4 register-vector copy and 84 add-one specializations. Complete equations do not imply graph safety; selected workgroup only. No performance or GPU execution claim.',
        'source_revision':'8cde3dd146bd1c4be78023b582c1f4375c48489f',
        'target':'gfx950','wave_size':64,'timeout_seconds':60,
        'builds':{role:build_record(args.builds/(stem+'-build.json'),EXPECTED[role])
                  for role,stem in [('previous','buffer'),('candidate','vector-coverage')]},
        'independent_raw_audit':{'sha256':hfile(args.audit),'script_sha256':audit['audit_script_sha256'],
            'checks':audit['checks'],'errors':0,'process_records':audit['audited_process_records'],
            'transcript_identity_chain_sha256':audit['transcript_identity_chain_sha256']},
        'historical_buffer_comparison_sha256':audit['original_public_buffer_comparison_sha256'],
        'profiles':{},'case_results':[],
        'limits':['Build source/binary association is caller-attested; committed-tree fingerprints and executable hashes were independently checked.',
                  'Arithmetic uses mathematical reals and encoded storage transport; bit-exact IEEE/hardware numerical correctness is outside this data.',
                  'Memory-conflict counts retain printed numeric witnesses and reported remaining counts; the complete event graphs are not part of this projection.',
                  'No timing/RSS, host/device identity, raw command or free diagnostic text is published.']}
    for role in ['previous','candidate']:
        require(result['builds'][role]['build_record_sha256']==audit['builds'][role]['build_record_sha256']
                and result['builds'][role]['binary_sha256']==audit['builds'][role]['binary_sha256'],
                'build record differs from independently audited identity')
    for family,(prefix,cardinality) in NAMES.items():
        reports, directories = {},{}
        for role, suffix in [('previous','buffer'),('candidate','complete')]:
            directory = args.reports/(prefix+'-'+suffix+'-candidate')
            report = read(directory/'report.json')
            require(report['profile']==family and report['source_revision']==result['source_revision']
                    and report['cases']==len(report['results'])==len({r['id'] for r in report['results']})==cardinality,
                    'full finite profile cardinality changed')
            reports[role],directories[role] = report,directory
        previous = {r['id']:r for r in reports['previous']['results']}
        candidate = {r['id']:r for r in reports['candidate']['results']}
        require(previous.keys()==candidate.keys(), 'variant case identities differ')
        result['profiles'][family] = {role:report_profile(directories[role],reports[role],role,audit)
                                      for role in ['previous','candidate']}
        transitions = Counter()
        for identifier in sorted(previous):
            old,new = previous[identifier],candidate[identifier]
            require({k:old[k] for k in IDENTITY}=={k:new[k] for k in IDENTITY}
                    and old['launch_sha256']==new['launch_sha256'], 'source case/launch differs')
            cfg = directories['candidate']/identifier/'launch.json'
            require(cfg.read_bytes()==(directories['previous']/identifier/'launch.json').read_bytes()
                    and hfile(cfg)==new['launch_sha256'], 'launch bytes changed')
            launch = read(cfg)
            require(set(launch)=={'kernel','block','grid','workgroup_id','dynamic_shared_bytes','arrays','params'}, 'unexpected launch fields')
            row = {'family':family,**{k:new[k] for k in IDENTITY},'launch_sha256':new['launch_sha256'],'launch':launch}
            for role,data in [('previous',old),('candidate',new)]:
                row[role] = {'status':data['status'],'full_specification_proved':data['full_specification_proved'],
                             'process':transcript(directories[role],data,'verify',data['stage'])}
                if 'full_identity_proved' in data:
                    row[role]['full_identity_proved'] = data['full_identity_proved']
            transitions[old['status']+' -> '+new['status']] += 1
            result['case_results'].append(row)
        result['profiles'][family]['transitions'] = dict(sorted(transitions.items()))
    require(len(result['case_results'])==336, 'comparison must retain all336 cases')
    result['summary'] = {role:{'outcomes':counts(r[role]['status'] for r in result['case_results']),
        'full_specifications':sum(r[role]['full_specification_proved'] for r in result['case_results']),
        'full_output_coordinates':sum(r['elements'] for r in result['case_results'] if r[role]['full_specification_proved'])}
        for role in ['previous','candidate']}
    text = json.dumps(result,indent=2)+'\n'
    require(not re.search(r'/tmp/|/home/|/opt/|[A-Z]:\\|hostname|device_identity|kernel_release|"seconds"|"cwd"',text,re.I),
            'unexpected private path, environment or timing field')
    if args.check:
        require(args.output.is_file() and args.output.read_bytes()==text.encode(), 'stale or missing public projection')
    else:
        require(not args.output.exists(), 'refusing to overwrite an existing projection')
        args.output.write_text(text)
    print(json.dumps({'sha256':hfile(args.output),'cases':len(result['case_results']),'summary':result['summary']},indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reports',type=Path,required=True)
    parser.add_argument('--builds',type=Path,required=True)
    parser.add_argument('--audit',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--check',action='store_true',help='Compare with an existing projection without writing')
    project(parser.parse_args())
