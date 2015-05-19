package errornotifier

import (
	"fmt"
	"log"
	"net/http"

	"github.com/codegangsta/negroni"
)

func NewRecoveryMiddleware(notifier Notifier) negroni.Handler {
	return &recoverer{notifier: notifier}
}

type recoverer struct {
	notifier Notifier
}

func (rec *recoverer) ServeHTTP(rw http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
	defer func() {
		if x := recover(); x != nil {
			if rec.notifier != nil {
				rec.notifier.Notify(fmt.Errorf("%v", x), r)
			}
			log.Printf("PANIC: %v", x)

			rw.WriteHeader(http.StatusInternalServerError)
		}
	}()

	next.ServeHTTP(rw, r)
}
