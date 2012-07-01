CXX = 'clang++'
LD  = CXX
LEX = 'flex'
YACC = 'bison'

BUILD_DIR = 'Build'

LEX_OUTPATH  = "#{BUILD_DIR}/lex.yy.mm"
YACC_OUTPATH = "#{BUILD_DIR}/y.tab.mm"

LEXFLAGS = [
	'-f',
	"-o #{LEX_OUTPATH}"
#	'-d'
].join(' ')

YACCFLAGS = [
	'-t',
	'-d',
	'-v',
	"-o #{YACC_OUTPATH}",
	#'-g',
	"--defines=#{BUILD_DIR}/y.tab.h"
].join(' ')

CXXFLAGS = [
	'-DDEBUG',
	'-std=gnu++98',
	'-mmacosx-version-min=10.7',
	'-I`pwd`/Source',
	'`llvm-config --cflags`',
	'-O0',
	'-g',
	'-std=gnu++98',
	'-ObjC++',
	#'--analyze'
].join(' ')


LDFLAGS = [
	'-lstdc++',
	'`llvm-config --libs`',
	'`llvm-config --ldflags`',
	'-framework Foundation'
].join(' ')

LIBS = ['-framework Foundation'].join(' ')

PATHMAP = "build/%n.o"

OBJC_SOURCES = FileList['Source*.m'].add('Source/*.mm').add(YACC_OUTPATH).add(LEX_OUTPATH)
O_FILES = OBJC_SOURCES.pathmap(PATHMAP)
LEX_SOURCE = FileList['*.l'].first
YACC_SOURCE = FileList['*.y'].first

def compile(file, flags=CXXFLAGS, cc=CXX)
	sh "#{cc} #{file[:in].join(' ')} #{flags} -c -o #{file[:out]}"
end

file YACC_OUTPATH => YACC_SOURCE do |f|
	sh "#{YACC} #{YACCFLAGS} #{YACC_SOURCE}"
end

file LEX_OUTPATH => LEX_SOURCE do |f|
	sh "#{LEX} #{LEXFLAGS} #{LEX_SOURCE}"
end

OBJC_SOURCES.each { |src|
	file src.pathmap(PATHMAP) => src do |f|
		compile :in => f.prerequisites, :out => f.name
	end
}

file :tranquil => O_FILES do |t|
	sh "#{LD} #{LDFLAGS} #{LIBS} #{O_FILES} -o #{BUILD_DIR}/#{t.name}"
end

task :default => [:tranquil]

task :run => [:default] do
	sh "#{BUILD_DIR}/tranquil"
end

task :gdb => [:default] do
	sh "gdb #{BUILD_DIR}/tranquil"
end

task :lldb => [:default] do
	sh "lldb #{BUILD_DIR}/tranquil"
end
