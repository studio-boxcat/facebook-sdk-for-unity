/**
 * Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
 *
 * You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 * copy, modify, and distribute this software in source code or binary form for use
 * in connection with the web services and APIs provided by Facebook.
 *
 * As with any software that integrates with the Facebook platform, your use of
 * this software is subject to the Facebook Developer Principles and Policies
 * [http://developers.facebook.com/policy/]. This copyright notice shall be
 * included in all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#pragma warning disable 618
namespace Facebook.Unity
{
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;
    using UnityEngine.Networking;

    /*
     * A short lived async request that loads a FBResult from a url endpoint
     */
    internal class AsyncRequestString : MonoBehaviour
    {
        private Uri url;
        private HttpMethod method;
        private IDictionary<string, string> formData;
        private WWWForm query;
        private FacebookDelegate<IGraphResult> callback;

        internal static void Post(
            Uri url,
            Dictionary<string, string> formData = null,
            FacebookDelegate<IGraphResult> callback = null)
        {
            Request(url, HttpMethod.POST, formData, callback);
        }

        internal static void Get(
            Uri url,
            Dictionary<string, string> formData = null,
            FacebookDelegate<IGraphResult> callback = null)
        {
            Request(url, HttpMethod.GET, formData, callback);
        }

        internal static void Request(
            Uri url,
            HttpMethod method,
            WWWForm query = null,
            FacebookDelegate<IGraphResult> callback = null)
        {
            ComponentFactory.AddComponent<AsyncRequestString>()
                .SetUrl(url)
                .SetMethod(method)
                .SetQuery(query)
                .SetCallback(callback);
        }

        internal static void Request(
            Uri url,
            HttpMethod method,
            IDictionary<string, string> formData = null,
            FacebookDelegate<IGraphResult> callback = null)
        {
            ComponentFactory.AddComponent<AsyncRequestString>()
                .SetUrl(url)
                .SetMethod(method)
                .SetFormData(formData)
                .SetCallback(callback);
        }

        internal IEnumerator Start()
        {
            UnityWebRequestAsyncOperation webRequestOperation;
            if (this.method == HttpMethod.GET)
            {
                string urlParams = this.url.AbsoluteUri.Contains("?") ? "&" : "?";
                if (this.formData != null)
                {
                    foreach (KeyValuePair<string, string> pair in this.formData)
                    {
                        urlParams += string.Format("{0}={1}&", Uri.EscapeDataString(pair.Key), Uri.EscapeDataString(pair.Value));
                    }
                }

                UnityWebRequest webRequest = UnityWebRequest.Get(url + urlParams);
                if (!Constants.IsWeb)
                {
                    webRequest.SetRequestHeader("User-Agent", Constants.GraphApiUserAgent);
                }

                webRequestOperation = webRequest.SendWebRequest();
            }
            else
            {
                // POST or DELETE
                if (this.query == null)
                {
                    this.query = new WWWForm();
                }

                if (this.method == HttpMethod.DELETE)
                {
                    this.query.AddField("method", "delete");
                }

                if (this.formData != null)
                {
                    foreach (KeyValuePair<string, string> pair in this.formData)
                    {
                        this.query.AddField(pair.Key, pair.Value);
                    }
                }

                if (!Constants.IsWeb)
                {
                    this.query.headers["User-Agent"] = Constants.GraphApiUserAgent;
                }

                UnityWebRequest webRequest = UnityWebRequest.Post(url.AbsoluteUri, query);
                webRequestOperation = webRequest.SendWebRequest();
            }

            yield return webRequestOperation;

            if (this.callback != null)
            {
                this.callback(new GraphResult(webRequestOperation));
            }

            // after the callback is called,  web request should be able to be disposed
            webRequestOperation.webRequest.Dispose();
            MonoBehaviour.Destroy(this);
        }

        internal AsyncRequestString SetUrl(Uri url)
        {
            this.url = url;
            return this;
        }

        internal AsyncRequestString SetMethod(HttpMethod method)
        {
            this.method = method;
            return this;
        }

        internal AsyncRequestString SetFormData(IDictionary<string, string> formData)
        {
            this.formData = formData;
            return this;
        }

        internal AsyncRequestString SetQuery(WWWForm query)
        {
            this.query = query;
            return this;
        }

        internal AsyncRequestString SetCallback(FacebookDelegate<IGraphResult> callback)
        {
            this.callback = callback;
            return this;
        }
    }
}
#pragma warning restore 618
