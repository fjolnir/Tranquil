CC    = '/usr/local/tranquil/llvm/bin/clang'
CXX   = '/usr/local/tranquil/llvm/bin/clang++'
LD    = CC
RAGEL = '/usr/local/bin/ragel'
LEMON = '/usr/local/bin/lemon'

MAXARGS = 32 # The number of block dispatchers to compile

BUILD_DIR = 'Build'

LEXER_OUTPATH    = "#{BUILD_DIR}/lex.mm"
PARSER_H_OUTPATH = "#{BUILD_DIR}/parse.h"
PARSER_OUTPATH   = "#{BUILD_DIR}/parse.mm"

CXXFLAGS = {
    :release => [
        '-mmacosx-version-min=10.7',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-I/usr/local/tranquil/gmp/include',
        '`/usr/local/tranquil/llvm/bin/llvm-config --cflags`',
        #'`/usr/local/llvm.dbg/bin/llvm-config --cflags`',
        '-O3',
    ].join(' '),
    :development => [
        '-DDEBUG',
        '-mmacosx-version-min=10.7',
        '-I`pwd`/Source',
        '-I`pwd`/Build',
        '-I/usr/include/libxml2',
        '-I/usr/local/tranquil/gmp/include',
        '`/usr/local/tranquil/llvm/bin/llvm-config --cflags`',
        #'`/usr/local/llvm.dbg/bin/llvm-config --cflags`',
        '-O0',
        '-g',
        #'-DTQ_PROFILE',
        #'--analyze'
    ].join(' ')
}

TOOL_LDFLAGS = [
    '-L`pwd`/Build',
    '-lstdc++',
    '`/usr/local/tranquil/llvm/bin/llvm-config --ldflags --libs core jit nativecodegen bitwriter ipo instrumentation`',
    #'`/usr/local/llvm.dbg/bin/llvm-config --ldflags --libs core jit nativecodegen bitwriter ipo instrumentation`',
    '-lclang',
    '-ltranquil',
    '-ltranquil_codegen',
    '/usr/local/tranquil/gmp/lib/libgmp.a',
    '-rpath /usr/local/tranquil/llvm/lib',
    #'-rpath /usr/local/llvm.dbg/lib',
    '-lffi',
    '-lreadline',
    #'-lprofiler',
    '-framework AppKit',
    '-all_load',
    '-g'
].join(' ')


LIBS = ['-framework Foundation', '-framework GLUT'].join(' ')

PATHMAP = 'build/%n.o'

STUB_OUTPATH    = 'Build/block_stubs.m'
STUB_SCRIPT     = 'Source/Tranquil/gen_stubs.rb'
STUB_H_OUTPATH  = 'Build/TQStubs.h'
STUB_H_SCRIPT   = 'Source/Tranquil/gen_stubs_header.rb'
MSGSEND_SOURCE  = 'Source/Tranquil/Runtime/msgsend.s'
MSGSEND_OUT     = 'Build/msgsend.o'
RUNTIME_SOURCES = FileList['Source/Tranquil/BridgeSupport/*.m*'].add('Source/Tranquil/Dispatch/*.m*').add('Source/Tranquil/Runtime/*.m*').add('Source/Tranquil/Shared/*.m*').add(STUB_OUTPATH)
RUNTIME_O_FILES = RUNTIME_SOURCES.pathmap(PATHMAP)
RUNTIME_O_FILES << MSGSEND_OUT

CODEGEN_SOURCES = FileList['Source/Tranquil/CodeGen/**/*.m*'] + [LEXER_OUTPATH]
CODEGEN_O_FILES = CODEGEN_SOURCES.pathmap(PATHMAP)

HEADERS         = FileList['Source/Tranquil/BridgeSupport/*.h'].add('Source/Tranquil/Dispatch/*.h').add('Source/Tranquil/Runtime/*.h').add('Source/Tranquil/Shared/*.h').add('Source/Tranquil/CodeGen/**/*.h')
HEADER_PATHMAP  = '/usr/local/tranquil/include/Tranquil/%-1d/%f'
HEADERS_OUT     = [STUB_H_OUTPATH] + HEADERS.pathmap(HEADER_PATHMAP)

LEXER_SOURCE    = "Source/lex.rl"
PARSER_SOURCE   = "Source/parse.y"

ARC_FILES = ['Source/Tranquil/Runtime/TQWeak.m']

MAIN_SOURCE  = 'Source/main.m'
MAIN_OUTPATH = 'Build/main.o'


@buildMode = :development

def compile(file, flags=CXXFLAGS, cc=CXX)
    cmd = "#{cc} #{file[:in].join(' ')} #{flags[@buildMode]} -c -o #{file[:out]}"
    cmd << " -fobjc-arc" if ARC_FILES.member? file[:in].first
    cmd << " -ObjC++"     if cc == CXX
    cmd << " -ObjC"       if cc == CC
    sh cmd
end

HEADERS.each { |header|
    file header.pathmap(HEADER_PATHMAP) => header do |f|
        p f.name
        sh "mkdir -p #{f.name.pathmap('%d')}"
        sh "cp #{header} #{f.name}"
    end
}


file LEXER_OUTPATH => LEXER_SOURCE do |f|
    sh "#{RAGEL} #{LEXER_SOURCE} -o #{LEXER_OUTPATH}"
end
file PARSER_OUTPATH => PARSER_SOURCE do |f|
    sh "#{LEMON} #{PARSER_SOURCE}"
    sh "mv Source/parse.c #{PARSER_OUTPATH}"
    sh "mv Source/parse.h #{PARSER_H_OUTPATH}"
end

file STUB_OUTPATH => STUB_SCRIPT do |f|
    sh "ruby #{STUB_SCRIPT} #{MAXARGS} > #{STUB_OUTPATH}"
end

file STUB_H_OUTPATH => STUB_H_SCRIPT do |f|
    sh "ruby #{STUB_H_SCRIPT} #{MAXARGS} > Build/TQStubs.h"
    sh "mkdir -p /usr/local/tranquil/include/Tranquil/Runtime"
    sh "cp Build/TQStubs.h /usr/local/tranquil/include/Tranquil/Runtime/TQStubs.h"
end


file MSGSEND_OUT => MSGSEND_SOURCE do |f|
    sh "#{CXX} #{MSGSEND_SOURCE} -c -o #{MSGSEND_OUT}"
end


RUNTIME_SOURCES.each { |src|
    file src.pathmap(PATHMAP) => src do |f|
        compile({:in => f.prerequisites, :out => f.name}, CXXFLAGS, CC)
    end
}
CODEGEN_SOURCES.each { |src|
    file src.pathmap(PATHMAP) => src do |f|
        compile :in => f.prerequisites, :out => f.name
    end
}


file :build_dir do
    sh "mkdir -p #{File.dirname(__FILE__)}/Build"
end

file :libtranquil => HEADERS_OUT + RUNTIME_O_FILES do |t|
    sh "libtool -static -o #{BUILD_DIR}/libtranquil.a #{RUNTIME_O_FILES}"
    sh "mkdir -p /usr/local/tranquil/lib"
    sh "cp Build/libtranquil.a /usr/local/tranquil/lib"
end

file :libtranquil_codegen => [PARSER_OUTPATH] + CODEGEN_O_FILES do |t|
    sh "ar rcs #{BUILD_DIR}/libtranquil_codegen.a #{CODEGEN_O_FILES}"
    sh "mkdir -p /usr/local/tranquil/lib"
    sh "cp Build/libtranquil_codegen.a /usr/local/tranquil/lib"
end

def _buildMain
    sh "#{CXX} #{MAIN_SOURCE} #{CXXFLAGS[@buildMode]} -ObjC++ -c -o #{MAIN_OUTPATH}"
end
file MAIN_OUTPATH => MAIN_SOURCE do |t|
end

file :tranquil => [:libtranquil, :libtranquil_codegen, MAIN_OUTPATH] do |t|
    _buildMain
    sh "#{LD} #{TOOL_LDFLAGS} #{LIBS} #{MAIN_OUTPATH} -ltranquil_codegen -o #{BUILD_DIR}/tranquil"
end

task :setReleaseOpts do
    p "Release build"
    @buildMode = :release
end

task :run => [:default] do
    sh "#{BUILD_DIR}/tranquil"
end

task :gdb => [:default] do
    sh "gdb #{BUILD_DIR}/tranquil"
end

task :lldb => [:default] do
    sh "lldb #{BUILD_DIR}/tranquil"
end

task :clean do
    sh "rm -rf Build/*"
end

task :install => [:tranquil] do
end

def _install
    sh "mkdir -p /usr/local/tranquil/bin"
    sh "cp Build/tranquil /usr/local/tranquil/bin"
    sh "cp Tools/repl.tq /usr/local/tranquil/bin/tqrepl"
    sh "cp Tools/tqlive.tq /usr/local/tranquil/bin/tqlive"
#    sh "/usr/local/tranquil/bin/tranquil Tools/tqc.tq Tools/tqc.tq -o /usr/local/tranquil/bin/tqc"
end

task :default => [:build_dir, :tranquil] do |t|
    _install
end
task :release => [:clean, :setReleaseOpts, :build_dir, :tranquil] do |t|
    _install
end
