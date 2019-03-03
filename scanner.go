package go_midl

import (
	"errors"
	"fmt"
	"io"
	"unicode"
)

type Scanner struct {
	lookupMap map[string]TokenType
	lastToken Token
	in        io.Reader
	err       error
	c         rune
}

func NewScanner(in io.Reader) *Scanner {
	s := Scanner{
		in: in,
	}
	return &s
}

func (s *Scanner) Read() bool {
	s.lastToken = Token{
		Type: ILLEGAL,
	}

	if s.c == 0 {
		if !s.next() {
			return false
		}
	}

	for {
		if !s.skipWhitespace() {
			return false
		}

		switch c := s.c; {
		case literalChar(c):
			t, v := s.findKeyword()
			s.lastToken = Token{
				Type: t,
				Val:  v,
			}
			return true
		case c == '/':
			if !s.skipComment() {
				s.err = errors.New("unexpected non-comment '/'")
				return false
			}
		case c == '#':
			if !s.skipLine() {
				s.err = errors.New("incorrect preprocessor directive")
				return false
			}
		case c == '"':
			if v, ok := s.findString(); ok {
				s.lastToken = Token{
					Type: STRING,
					Val:  v,
				}
			}
		case c == '(':
			s.lastToken.Type = LPAREN
		case c == ')':
			s.lastToken.Type = RPAREN
		case c == '[':
			s.lastToken.Type = LBRACK
		case c == ']':
			s.lastToken.Type = RBRACK
		case c == '{':
			s.lastToken.Type = LBRACE
		case c == '}':
			s.lastToken.Type = RBRACE
		case c == ':':
			s.lastToken.Type = COLON
		case c == ',':
			s.lastToken.Type = COMMA
		case c == ';':
			s.lastToken.Type = SEMICOLON
		case c == '*':
			s.lastToken.Type = PTR
		case c == '=':
			s.lastToken.Type = EQUALS
		case c == '|':
			s.lastToken.Type = B_OR
		default:
			s.err = fmt.Errorf("unexpected character '%c'", c)
			return false
		}

		if s.lastToken.Type != ILLEGAL {
			s.c = 0
			return true
		}
	}
}

func literalChar(c rune) bool {
	return unicode.IsLetter(c) ||
		unicode.IsDigit(c) ||
		c == '-' ||
		c == '_' ||
		c == '.'
}

func keywordChar(c rune) bool {
	return unicode.IsLetter(c) || c == '_' || unicode.IsDigit(c)
}

func (s *Scanner) findKeyword() (TokenType, string) {
	token := string(s.c)

	literal := false
	number := false
	if unicode.IsDigit(s.c) {
		number = true
	}
	for {
		if !s.next() {
			return EOF, ""
		}
		if number {
			if !unicode.IsDigit(s.c) &&
				!(len(token) == 1 &&
					token[0] == '0' &&
					(s.c == 'x' || s.c == 'X')) {
				if literalChar(s.c) {
					number = false
				} else {
					break
				}
			}
		}

		if !number && !literal && !keywordChar(s.c) {
			if !literalChar(s.c) {
				break
			}
			literal = true
		} else if !number && literal && !literalChar(s.c) {
			break
		}
		token += string(s.c)
	}
	if !literal {
		t := keyword(token)
		if t != ILLEGAL {
			return t, ""
		}
	}
	if number {
		return NUM, token
	}
	return IDENT, token
}

func (s *Scanner) skipWhitespace() bool {
	for {
		if s.c != '\n' && s.c != '\r' && s.c != ' ' && s.c != '\t' {
			return true
		}
		if !s.next() {
			return false
		}

	}
}

func (s *Scanner) skipLine() bool {
	for s.next() {
		if s.c == '\n' {
			return true
		}
	}
	return false
}

func (s *Scanner) skipComment() bool {
	if s.c == '/' && s.next() && s.c == '/' {
		for s.next() {
			if s.c == '\n' {
				return true
			}
		}
	}
	return false
}

func (s *Scanner) next() bool {
	buf := make([]byte, 1, 1)
	n, err := s.in.Read(buf)
	if err != nil {
		s.err = err
		return false
	}
	if n != 1 {
		s.err = errors.New("could not read single char")
		return false
	}
	s.c = rune(buf[0])
	return true
}

func (s *Scanner) findString() (string, bool) {
	// escaping not supported
	v := ""
	for s.next() {
		if s.c == '"' {
			return v, true
		}
		v += string(s.c)
	}
	return "", false
}

func (s *Scanner) LastToken() Token {
	return s.lastToken
}

func (s *Scanner) Error() error {
	return s.err
}
