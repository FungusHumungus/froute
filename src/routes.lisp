(in-package :froute)



(defstruct route path class children) 



(defmethod collect-inherited-routes ((class froute-class))
  "Retrieves all routes in the inheritance tree that are froutes."
  (flet ((is-froute (class) (typep class 'froute-class)))
    (remove-if-not  #'is-froute (class-precedence-list class))))

(defun find-route (path list)
  "Finds the route with the path in the given list"
  (find path list :test #'string= :key #'route-path))


(defun insert-into-position (value list &key (test #'>) (key #'identity))
  "Insert the value into the list where every item that fails the test preceeds the value
and every item that passes the test follows."
  (flet ((test-on-value (item)
           (funcall test (funcall key value) item)))
    `(,@(remove-if-not #'test-on-value list :key key)
        ,value
        ,@(remove-if #'test-on-value list :key key))))

(defmethod num-segments ((route route))
  (length (split-route (route-path route))))

(defmethod push-route ((class froute-class))
  "Pushes a new route into our route tree"
  (labels ((recurse (routes list)
             (let* ((head (car routes))
                    (tail (cdr routes))
                    (head-path (car (route head)))
                    (route (or (find-route head-path list)
                               (let ((new-route (make-route :path head-path
                                                            :class head)))
                                 (setf list (insert-into-position new-route list
                                                                  :key #'num-segments
                                                                  :test #'<))
                                 new-route))))
               
               (when tail
                 (setf (route-children route)
                       (recurse tail (route-children route))))
                 
               list)))

    (let ((routes (reverse (collect-inherited-routes class))))
      (setf *routes*
            (recurse routes *routes*)))))

(defmethod clean-route ((class froute-class))
  "Removes all instances of the given class from our route tree"
  (labels ((clean (list)
             (remove-if (lambda (route) 
                          (equal 
                           (class-name (route-class route))
                           (class-name class)))
                        list))
           (recurse (list)
             (mapcar (lambda (route)
                       (setf (route-children route)
                             (recurse (route-children route)))
                       route)
                     (clean list))))
    (setf *routes*
          (recurse *routes*))))

(defun build-routes ()
  "Clears our routes mapping and builds it up from scratch."
  (setf *routes* '())
  (loop for route in *route-classes*
       do
       (push-route route)))
