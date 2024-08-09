import { markdown, fail } from 'danger';
import { readFileSync } from 'fs';

//  ★ Dartフォーマットのレポートを行う。
//  (コマンド: dart format ./ > dart_format_report.txt)

//  フォーマット結果の文字列から、フォーマットが掛けられたDartファイルのパスを抜き出す。
//  NOTE:
//   フォーマットが掛けられた場合、コンソールに「Formatted lib/〇〇.dart」という出力が行われる。
//   ここから正規表現によってDartファイルのパスを抜き出す。
function parseFormattedFilePath(line: string): string | null {
    const matchResult: RegExpMatchArray | null = line.match(/^Formatted (.+).dart$/);
    if (matchResult == null) return null;

    return `${matchResult[1]}.dart`;
}

//  レポートファイルからフォーマットが掛けられたDartファイルのパス一覧を取得する。
//  (フォーマットの必要なかった場合は空配列となる。)
const dartFormatReport: string = readFileSync('dart_format_report.txt', 'utf-8');
const formattedFilePaths: string[] = dartFormatReport
    .split('\n')
    .map((line: string) => parseFormattedFilePath(line))
    .filter((path: string | null): path is string => path != null)

//  フォーマットが掛けられたDartファイルが1つでも存在する場合、DangerによってPRにコメントを付ける。
if (formattedFilePaths.length != 0) {
    markdown('## Dart Format Report\n');
    markdown(`${formattedFilePaths.length} issue(s) found.\n`);
    for (const path of formattedFilePaths) markdown(`* ${path}`);

    fail(`Dart Format Report: ${formattedFilePaths.length} issue(s) found.`);
}

//  ★ Flutter Analyzeのレポートを行う。
//  (コマンド: flutter analyze > flutter_analyze_report.txt)

//  Analyze結果の文字列から、指摘されたissueを抜き出す。
//  NOTE:
//   問題が指摘された場合、コンソールに「info • Use 'const' with the constructor to improve performance • lib/〇〇.dart:〇〇:〇〇 • prefer_const_constructors」などといった出力が行われる。
//   ここから正規表現によって レベル / メッセージ / 該当ファイルパス / ルールID を抜き出す。
interface Issue { level: string; message: string; file: string; rule: string; }
function parseIssueLine(line: string): Issue | null {
    const result: RegExpMatchArray | null = line.match(/(\s*)(info|warning|error) • (.+) • (.+) • (.+)/);
    if (result == null) return null;

    return { level: result[2], message: result[3], file: result[4], rule: result[5] };
}

//  レポートファイルから指摘されたissue一覧を取得する。
//  (指摘がなかった場合は空配列となる。)
const flutterAnalyzeReport: string = readFileSync('flutter_analyze_report.txt', 'utf-8');
const analysisIssues: Issue[] = flutterAnalyzeReport
    .split('\n')
    .map((line: string) => parseIssueLine(line))
    .filter((issue: Issue | null): issue is Issue => issue != null);

//  指摘が1つでも存在する場合、DangerによってPRにコメントを付ける。
if (analysisIssues.length != 0) {
    let table = '| Level | Message | File | Rule |\n|:---|:---|:---|:---|\n';
    for (const issue of analysisIssues) {
        const ruleLink = `[${issue.rule}](https://dart.dev/tools/linter-rules/${issue.rule})`;
        table += `| ${issue.level} | ${issue.message} | ${issue.file} | ${ruleLink} |\n`;
    }

    markdown('## Flutter Analyze Report\n');
    markdown(`${analysisIssues.length} issue(s) found.\n`);
    markdown(table);

    fail(`Flutter Analyze Report: ${analysisIssues.length} issue(s) found.`);
}

//  ★ custom_lintのレポートを行う。
//  (コマンド: dart run custom_lint > custom_lint_report.txt)

//  custom_lint結果の文字列から、指摘されたissueを抜き出す。
//  NOTE:
//   問題が指摘された場合、コンソールに
//   「  lib/〇〇.dart:〇〇:〇〇 • Flutter applications should have a ProviderScope widget at the top of the widget tree. • missing_provider_scope • INFO」
//   などといった出力が行われる。
//   ここから正規表現によって レベル / メッセージ / 該当ファイルパス / ルールID を抜き出す。
function parseCustomLintIssueLine(line: string): Issue | null {
    const result: RegExpMatchArray | null = line.match(/(\s*)(.+) • (.+) • (.+) • (.+)/);
    if (result == null) return null;

    return { level: result[5], message: result[3], file: result[2], rule: result[4] };
}

//  custom_lintのレポートファイルから指摘されたissue一覧を取得する。
//  (指摘がなかった場合は空配列となる。)
const customLintReport: string = readFileSync('custom_lint_report.txt', 'utf-8');
const customLintIssues: Issue[] = customLintReport
    .split('\n')
    .map((line: string) => parseCustomLintIssueLine(line))
    .filter((issue: Issue | null): issue is Issue => issue != null);

//  指摘が1つでも存在する場合、DangerによってPRにコメントを付ける。
if (customLintIssues.length != 0) {
    let table = '| Level | Message | File | Rule |\n|:---|:---|:---|:---|\n';
    for (const issue of customLintIssues) {
        table += `| ${issue.level} | ${issue.message} | ${issue.file} | ${issue.rule} |\n`;
    }

    markdown('## Custom Lint Report\n');
    markdown(`${customLintIssues.length} issue(s) found.\n`);
    markdown(table);

    fail(`Custom Lint Report: ${customLintIssues.length} issue(s) found.`);
}
